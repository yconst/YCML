//
//  CrossValidation.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 28/4/15.
//  Copyright © 2015 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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
#import "YCMutableArray.h"

@implementation YCkFoldValidation
{
    int _currentFold;
}

- (instancetype)initWithSettings:(NSDictionary *)settings evaluator:(NSDictionary *(^)(YCDataframe *, YCDataframe *, YCDataframe *))evaluator
{
    self = [super initWithSettings:settings evaluator:evaluator];
    if (self)
    {
        if (!self.settings[@"Folds"])
        {
            self.settings[@"Folds"] = @5;
        }
    }
    return self;
}

- (NSDictionary *)performTest:(YCSupervisedTrainer *)trainer
                        input:(YCDataframe *)input
                       output:(YCDataframe *)output
{
    NSAssert([input dataCount] == [output dataCount], @"Sample counts differ");
    
    NSMutableDictionary<NSString *,YCMutableArray *> *allStats = [NSMutableDictionary dictionary];
    NSMutableArray *models = [NSMutableArray array];
    
    int folds = [self.settings[@"Folds"] intValue];
    
    int foldLength = (int)([input dataCount] / folds);
        
    for (int i=0; i<folds; i++)
    {
        @autoreleasepool
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
            
            if (!model) break;
            
            YCDataframe *predictedOutput = [model activateWithDataframe:trimmedTestInput];
            
            NSDictionary *output = self.evaluator(trimmedTestInput, trimmedTestOutput, predictedOutput);
            
            for (NSString *key in output.allKeys)
            {
                if (!allStats[key])
                {
                    allStats[key] = [YCMutableArray array];
                }
                [allStats[key] addObject:output[key]];
            }
            
            [models addObject:model];
        }
    }
    
    self.results = [allStats copy];
    self.models = models;
    
    NSMutableDictionary<NSString *,NSNumber *> *cumulativeStats = [NSMutableDictionary dictionary];
    
    for (NSString *key in allStats)
    {
        cumulativeStats[key] = [allStats[key] mean];
    }
    
    return trainer.shouldStop ? nil : cumulativeStats;
}

#pragma mark YCTrainerDelegate Implementation

- (void)stepComplete:(NSDictionary *)info
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stepComplete:)])
    {
        NSMutableDictionary *userInfo = [info mutableCopy];
        userInfo[@"Total Folds"] = self.settings[@"Folds"];
        userInfo[@"Current Fold"] = @(_currentFold);
        [self.delegate stepComplete:userInfo];
    }
}

@end
