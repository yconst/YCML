//
//  YCPopulationBasedOptimizer.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 29/6/15.
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

#import "YCPopulationBasedOptimizer.h"
#import "YCIndividual.h"
@import YCMatrix;

@implementation YCPopulationBasedOptimizer

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem
{
    self = [super initWithProblem:aProblem];
    if (self)
    {
        self.population = [NSMutableArray array];
        self.settings[@"Population Size"] = @100;
    }
    return self;
}

- (void)evaluateIndividuals:(NSArray *)individuals
{
    NSAssert(self.problem, @"Property 'problem' is nil");

    int objectiveCount = self.problem.objectiveCount;
    int constraintCount = self.problem.constraintCount;
    
    Matrix *result = [Matrix matrixOfRows:(objectiveCount+constraintCount) Columns:1];
    
    for (YCIndividual *i in individuals)
    {
        if (i.evaluated) continue;
        
        [self.problem evaluate:result parameters:i.decisionVariableValues];
        
        NSRange constraintRange = NSMakeRange(0, constraintCount);
        i.constraintValues = [result matrixWithRowsInRange:constraintRange];
        
        NSRange objectiveRange = NSMakeRange(constraintCount, objectiveCount);
        i.objectiveFunctionValues = [result matrixWithRowsInRange:objectiveRange];
        
        i.evaluated = YES;
    }
}

- (void)reset
{
    [super reset];
    self.population = [NSMutableArray array];
}

- (NSArray *)bestParameters
{
    return [self.population valueForKey:@"decisionVariableValues"];
}

- (NSArray *)bestObjectives
{
    return [self.population valueForKey:@"objectiveFunctionValues"];
}

#pragma mark NSCopying implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCPopulationBasedOptimizer *opt = [super copyWithZone:zone];
    if (opt)
    {
        opt.population = [self.population mutableCopy];
    }
    return opt;
}


#pragma mark NSCoding implementation

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.population = [aDecoder decodeObjectForKey:@"population"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.population forKey:@"population"];
}

@end
