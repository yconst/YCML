//
//  CrossValidation.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 28/4/15.
//  Copyright (c) 2015 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
//
// This file is part of YCML.
//
// YCML is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// YCML is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with YCML.  If not, see <http://www.gnu.org/licenses/>..

#import "YCCrossValidation.h"
#import "YCSupervisedModel.h"
#import "YCSupervisedTrainer.h"
#import "YCDataframe.h"
#import "YCRegressionMetrics.h"
#import "NSArray+Statistics.h"

@implementation YCCrossValidation
{
    int _currentFold;
}

+ (instancetype)validationWithSettings:(NSDictionary *)settings
{
    return [[self alloc] initWithSettings:settings];
}

- (instancetype)init
{
    return [self initWithSettings:nil evaluator:nil];
}

- (instancetype)initWithSettings:(NSDictionary *)settings
{
    return [self initWithSettings:settings evaluator:nil];
}

- (instancetype)initWithSettings:(NSDictionary *)settings
                       evaluator:(NSDictionary *(^)(YCDataframe *, YCDataframe *,
                                                    YCDataframe *, YCDataframe *,
                                                    YCDataframe *))evaluator
{
    self = [super init];
    if (self)
    {
        self.settings = [NSMutableDictionary dictionary];
        self.settings[@"Folds"] = @5;
        if (settings) [self.settings addEntriesFromDictionary:settings];
        if (evaluator)
        {
            self.evaluator = evaluator;
        }
        else
        {
            self.evaluator = ^NSDictionary *(YCDataframe *tri, YCDataframe *tro,
                                             YCDataframe *tsi, YCDataframe *tso, YCDataframe *po)
            {
                return @{@"RMSE" : @(sqrt(MSE(tso, po))),
                         @"RSquared" : @(RSquared(tso, po))};
            };
        }
    }
    return self;
}

- (NSDictionary *)test:(YCSupervisedTrainer *)trainer
         trainingInput:(YCDataframe *)trainingInput trainingOutput:(YCDataframe *)trainingOutput
             testInput:(YCDataframe *)testInput testOutput:(YCDataframe *)testOutput
{
    NSAssert([trainingInput dataCount] == [trainingOutput dataCount] &&
             [testInput dataCount] == [testOutput dataCount] &&
             [trainingInput dataCount] == [testInput dataCount], @"Sample counts differ");
    NSAssert([trainingInput attributeCount] == [testInput attributeCount] &&
             [trainingOutput attributeCount] == [testOutput attributeCount], @"Sample sizes differ");
    
    NSMutableDictionary *cumulativeStats = [NSMutableDictionary dictionary];
    NSMutableArray *models = [NSMutableArray array];
    
    int folds = [self.settings[@"Folds"] intValue];
    
    int foldLength = (int)([testInput dataCount] / folds);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTrainingStep:)
                                                 name:@"TrainingStep"
                                               object:trainer];
    for (int i=0; i<folds; i++)
    {
        _currentFold = i;
        
        NSIndexSet *testIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i*foldLength, foldLength)];
        
        YCDataframe *trimmedTrainingInput = [YCDataframe dataframe];
        [trimmedTrainingInput addSamplesWithData:[trainingInput samplesNotInIndexes:testIndexes]];
        YCDataframe *trimmedTrainingOutput = [YCDataframe dataframe];
        [trimmedTrainingOutput addSamplesWithData:[trainingOutput samplesNotInIndexes:testIndexes]];
        YCDataframe *trimmedTestInput = [YCDataframe dataframe];
        [trimmedTestInput addSamplesWithData:[testInput samplesAtIndexes:testIndexes]];
        YCDataframe *trimmedTestOutput = [YCDataframe dataframe];
        [trimmedTestOutput addSamplesWithData:[testOutput samplesAtIndexes:testIndexes]];
        
        YCSupervisedModel *model = [trainer train:nil input:trimmedTrainingInput output:trimmedTrainingOutput];
        YCDataframe *predictedOutput = [model activateWithDataframe:trimmedTestInput];
        
        NSDictionary *output = self.evaluator(trimmedTrainingInput, trimmedTrainingOutput,
                                              trimmedTestInput, trimmedTestOutput, predictedOutput);
        
        for (NSString *key in output.allKeys)
        {
            if (!cumulativeStats[key])
            {
                cumulativeStats[key] = [NSMutableArray array];
            }
            [cumulativeStats[key] addObject:output[key]];
        }
        
        [models addObject:model];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.results = [cumulativeStats copy];
    self.models = models;
    
    for (NSString *key in cumulativeStats.allKeys)
    {
        cumulativeStats[key] = [cumulativeStats[key] mean];
    }
    return cumulativeStats;
}

- (NSDictionary *)test:(YCSupervisedTrainer *)trainer input:(YCDataframe *)input output:(YCDataframe *)output
{
    return [self test:trainer trainingInput:input trainingOutput:output testInput:input testOutput:output];
}

#pragma mark Notifications

- (void)handleTrainingStep:(NSNotification *)aNotification
{
    NSMutableDictionary *userInfo = [aNotification.userInfo mutableCopy];
    userInfo[@"Total Folds"] = self.settings[@"Folds"];
    userInfo[@"Current Fold"] = @(_currentFold);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CVStep"
                                                        object:self
                                                      userInfo:userInfo];
}

@end
