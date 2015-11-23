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

#import "YCkFoldValidation.h"
#import "YCSupervisedModel.h"
#import "YCSupervisedTrainer.h"
#import "YCDataframe.h"
#import "YCRegressionMetrics.h"
#import "NSArray+Statistics.h"

@implementation YCkFoldValidation
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
            self.evaluator = ^NSDictionary *(YCDataframe *ti, YCDataframe *to, YCDataframe *po)
            {
                return @{@"RMSE" : @(sqrt(MSE(to, po))),
                         @"RSquared" : @(RSquared(to, po))};
            };
        }
    }
    return self;
}

- (NSDictionary *)test:(YCSupervisedTrainer *)trainer input:(YCDataframe *)input output:(YCDataframe *)output
{
    NSAssert([input dataCount] == [output dataCount], @"Sample counts differ");
    
    NSMutableDictionary *cumulativeStats = [NSMutableDictionary dictionary];
    NSMutableArray *models = [NSMutableArray array];
    
    int folds = [self.settings[@"Folds"] intValue];
    
    int foldLength = (int)([input dataCount] / folds);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTrainingStep:)
                                                 name:@"TrainingStep"
                                               object:trainer];
    for (int i=0; i<folds; i++)
    {
        _currentFold = i;
        
        NSIndexSet *testIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i*foldLength, foldLength)];
        
        YCDataframe *trimmedInput = [YCDataframe dataframe];
        [trimmedInput addSamplesWithData:[input samplesNotInIndexes:testIndexes]];
        YCDataframe *trimmedOutput = [YCDataframe dataframe];
        [trimmedOutput addSamplesWithData:[output samplesNotInIndexes:testIndexes]];
        YCDataframe *trimmedTestInput = [YCDataframe dataframe];
        [trimmedTestInput addSamplesWithData:[input samplesAtIndexes:testIndexes]];
        YCDataframe *trimmedTestOutput = [YCDataframe dataframe];
        [trimmedTestOutput addSamplesWithData:[output samplesAtIndexes:testIndexes]];
        
        YCSupervisedModel *model = [trainer train:nil input:trimmedInput output:trimmedOutput];
        YCDataframe *predictedOutput = [model activateWithDataframe:trimmedTestInput];
        
        NSDictionary *output = self.evaluator(trimmedTestInput, trimmedTestOutput, predictedOutput);
        
        for (NSString *key in output.allKeys)
        {
            if (!cumulativeStats[key])
            {
                cumulativeStats[key] = [NSMutableArray array];
            }
            [cumulativeStats[key] addObject:output[key]];
        }
        
        [models addObject:model];
        
        if (trainer.shouldStop) break;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.results = [cumulativeStats copy];
    self.models = models;
    
    for (NSString *key in cumulativeStats.allKeys)
    {
        cumulativeStats[key] = [cumulativeStats[key] mean];
    }
    
    return trainer.shouldStop ? nil : cumulativeStats;

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
