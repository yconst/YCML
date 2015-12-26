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

+ (Class)individualClass
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem settings:(NSDictionary *)settings
{
    self = [super initWithProblem:aProblem settings:settings];
    if (self)
    {
        self.settings[@"Population Size"] = @100;
    }
    return self;
}

- (void)initializePopulation
{
    NSAssert(self.problem, @"Property 'problem' is nil");
    int popSize = [self.settings[@"Population Size"] intValue];
    
    self.population = [NSMutableArray array];
    Matrix *parameterBounds = [self.problem parameterBounds];
    for (int i=0; i<popSize; i++)
    {
        [self.population addObject:[[[[self class] individualClass] alloc]
                                    initWithRandomValuesInBounds:parameterBounds]];
    }
}

- (void)replacePopulationUsing:(Matrix *)data
{
    NSAssert(self.problem, @"Property 'problem' is nil");
    NSAssert(data.rows == self.problem.parameterCount, @"");
    NSAssert(data.columns > 0, @"Supplied data matrix is empty");
    
    NSArray *dataArray = [data columnsAsNSArray];
    
    self.population = [NSMutableArray array];
    for (int i=0, j=(int)dataArray.count; i<j; i++)
    {
        YCIndividual *newIndividual = [[[[self class] individualClass] alloc] init];
        newIndividual.decisionVariableValues = dataArray[i];
        [self.population addObject:newIndividual];
    }
    
    self.settings[@"Population Size"] = @(dataArray.count);
}

- (void)evaluateIndividuals:(NSArray *)individuals
{
    NSAssert(self.problem, @"Property 'problem' is nil");
    NSAssert(individuals, @"Passed individuals parameter is nil");
    
    // Pick out only the individuals that have not been evaluated
    NSArray *ne = [individuals objectsAtIndexes:[individuals indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx,BOOL * _Nonnull stop) {
        return !((YCIndividual *)obj).evaluated;
    }]];
    
    int parameterCount = self.problem.parameterCount;
    int objectiveCount = self.problem.objectiveCount;
    int constraintCount = self.problem.constraintCount;
    int populationCount = (int)ne.count;
    
    if (populationCount == 0) return; // Nothing to evaluate really..
    
    if (self.problem.supportedEvaluationMode == YCProvidesParallelImplementation)
    {
        Matrix *parameters = [Matrix matrixOfRows:parameterCount
                                          columns:populationCount];
        [ne enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCIndividual *individual = obj;
            [parameters setColumn:(int)idx value:individual.decisionVariableValues];
        }];
        
        Matrix *results = [Matrix matrixOfRows:(objectiveCount+constraintCount)
                                      columns:populationCount];
        
        [self.problem evaluate:results parameters:parameters];
        
        [ne enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCIndividual *individual = obj;
            Matrix *result = [results column:(int)idx];
            
            NSRange constraintRange = NSMakeRange(0, constraintCount);
            individual.constraintValues = [result matrixWithRowsInRange:constraintRange];
            
            NSRange objectiveRange = NSMakeRange(constraintCount, objectiveCount);
            individual.objectiveFunctionValues = [result matrixWithRowsInRange:objectiveRange];
            
            individual.evaluated = YES;
        }];
    }
    else
    {
        Matrix *result = [Matrix matrixOfRows:(objectiveCount+constraintCount) columns:1];
        
        for (YCIndividual *individual in ne)
        {
            [self.problem evaluate:result parameters:individual.decisionVariableValues];
            
            NSRange constraintRange = NSMakeRange(0, constraintCount);
            individual.constraintValues = [result matrixWithRowsInRange:constraintRange];
            
            NSRange objectiveRange = NSMakeRange(constraintCount, objectiveCount);
            individual.objectiveFunctionValues = [result matrixWithRowsInRange:objectiveRange];
            
            individual.evaluated = YES;
        }
    }
}

- (void)reset
{
    [super reset];
    self.population = nil;
}

- (NSArray *)bestParameters
{
    if (!self.population) [self initializePopulation];
    return [self.population valueForKey:@"decisionVariableValues"];
}

- (NSArray *)bestObjectives
{
    if (!self.population) [self initializePopulation];
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
