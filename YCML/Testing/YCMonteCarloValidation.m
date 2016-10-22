//
//  YCMonteCraloValidation.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 19/10/15.
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
// along with YCML.  If not, see <http://www.gnu.org/licenses/>.

#import "YCMonteCarloValidation.h"
#import "YCSupervisedModel.h"
#import "YCSupervisedTrainer.h"
#import "YCDataframe.h"
#import "YCRegressionMetrics.h"
#import "YCMutableArray.h"
#import "NSIndexSet+Sampling.h"

@implementation YCMonteCarloValidation
{
    double _currentIteration;
}

- (instancetype)initWithSettings:(NSDictionary *)settings evaluator:(NSDictionary *(^)(YCDataframe *, YCDataframe *, YCDataframe *))evaluator
{
    self = [super initWithSettings:settings evaluator:evaluator];
    if (self)
    {
        if (!self.settings[@"Iterations"])
        {
            self.settings[@"Iterations"] = @5;
        }
        if (!self.settings[@"TestFactor"])
        {
            self.settings[@"TestFactor"] = @0.1;
        }
    }
    return self;
}

- (NSDictionary *)performTest:(YCSupervisedTrainer *)trainer
                        input:(YCDataframe *)input
                       output:(YCDataframe *)output
{
    NSAssert([input dataCount] == [output dataCount], @"Sample counts differ");
    
    NSMutableDictionary<NSString *, YCMutableArray *> *allStats = [NSMutableDictionary dictionary];

    NSMutableArray<YCSupervisedModel *> *models = [NSMutableArray array];
    
    int iterations = [self.settings[@"Iterations"] intValue];
    
    int testSize = (int)([input dataCount] * [self.settings[@"TestFactor"] doubleValue]);
    
    for (int i=0; i<iterations; i++)
    {
        @autoreleasepool
        {
            _currentIteration = i;
            
            NSIndexSet *testIndexes = [NSIndexSet indexesForSampling:testSize
                                                             inRange:NSMakeRange(0, input.dataCount)
                                                         replacement:NO];
            
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
                NSAssert(!isnan([output[key] doubleValue]), @"Prediction value is NaN");
                [allStats[key] addObject:output[key]];
            }
            
            [models addObject:model];
        }
    }
    
    self.results = [allStats copy];
    self.models = models;
    
    NSMutableDictionary<NSString *, NSNumber *> *cumulativeStats = [NSMutableDictionary dictionary];
    
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
        userInfo[@"Total Iterations"] = self.settings[@"Iterations"];
        userInfo[@"Current Iteration"] = @(_currentIteration);
        [self.delegate stepComplete:userInfo];
    }
}

@end
