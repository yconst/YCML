//
//  YCCompoundProblem.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 2/3/15.
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
// along with YCML.  If not, see <http://www.gnu.org/licenses/>.

#import "YCCompoundProblem.h"
@import YCMatrix;

@implementation YCCompoundProblem

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.problems = [NSMutableArray array];
    }
    return self;
}

- (int)objectiveCount
{
    int count = 0;
    for (id<YCProblem> p in self.problems)
    {
        count += [p objectiveCount];
    }
    return count;
}

- (int)parameterCount
{
    if (!self.problems.count)
    {
        return 0;
    }
    return [self.problems[0] parameterCount];
}

- (int)constraintCount
{
    int count = 0;
    for (id<YCProblem> p in self.problems)
    {
        count += [p constraintCount];
    }
    return count;
}

- (Matrix *)parameterBounds
{
    if (!self.problems.count)
    {
        return nil;
    }
    return [self.problems[0] parameterBounds];
}

- (Matrix *)initialValuesRangeHint
{
    if (!self.problems.count)
    {
        return nil;
    }
    return [self.problems[0] initialValuesRangeHint];
}

- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters
{
    NSMutableArray *compoundObjectives = [NSMutableArray array];
    NSMutableArray *compoundConstraints = [NSMutableArray array];
    
    for (id<YCProblem> p in self.problems)
    {
        Matrix *result = [Matrix matrixOfRows:[p objectiveCount] + [p constraintCount] Columns:1];
        [p evaluate:result parameters:parameters];
        NSArray *resultArray = [result numberArray];
        NSArray *objectiveArray = [resultArray subarrayWithRange:NSMakeRange(0,
                                                                             [p objectiveCount])];
        NSArray *constraintArray = [resultArray subarrayWithRange:NSMakeRange([p objectiveCount] - 1,
                                                                              [p constraintCount])];
        [compoundObjectives addObjectsFromArray:objectiveArray];
        [compoundConstraints addObjectsFromArray:constraintArray];
    }
    
    [compoundObjectives addObjectsFromArray:compoundConstraints];
    Matrix *compoundMatrix = [Matrix matrixFromNSArray:compoundObjectives
                                                  Rows:(int)compoundObjectives.count
                                               Columns:1];
    [target copyValuesFrom:compoundMatrix];
}

- (NSArray *)parameterLabels
{
    if (!self.problems.count)
    {
        return nil;
    }
    return [self.problems[0] parameterLabels];
}

- (NSArray *)objectiveLabels
{
    NSMutableArray *labels = [NSMutableArray array];
    for (id<YCProblem> p in self.problems)
    {
        [labels addObjectsFromArray:[p objectiveLabels]];
    }
    return labels;
}

- (NSArray *)constraintLabels
{
    NSMutableArray *labels = [NSMutableArray array];
    for (id<YCProblem> p in self.problems)
    {
        [labels addObjectsFromArray:[p constraintLabels]];
    }
    return labels;
}

- (NSArray *)dictionary:(NSDictionary *)dictionary toArrayWithKeyOrder:(NSArray *)order
{
    NSMutableArray *output = [NSMutableArray array];
    for (id key in order)
    {
        if (dictionary[key])
        {
            [output addObject:dictionary[key]];
        }
    }
    return output;
}

@end
