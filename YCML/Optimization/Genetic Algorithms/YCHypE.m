//
//  YCHYPE.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 13/1/16.
//  Copyright (c) 2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

#define ARC4RANDOM_MAX      0x100000000
#define firstRank           1

#import "YCHypE.h"
@import YCMatrix;

@interface NSMutableArray (Shuffling)

- (void)shuffle;

@end

@implementation YCHypE
{
    Matrix *_modesCache;
    Matrix *_upper;
    Matrix *_lower;
}

+ (Class)individualClass
{
    return [YCHypEIndividual class];
}

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem settings:(NSDictionary *)settings
{
    self = [super initWithProblem:aProblem settings:settings];
    if (self)
    {
        self.settings[@"Hypervolume Samples"] = @5000;
        self.settings[@"Crossover Probability"] = @1.0;
        self.settings[@"Mutation Probability"] = @0.1;
        self.settings[@"NC"] = @15.0;
        self.settings[@"NM"] = @20.0;
        self.settings[@"Individual MP"] = @0.5;
    }
    return self;
}

- (BOOL)iterate:(int)iteration
{
    if (!_modesCache) _modesCache = self.problem.modes;
    
    if (!self.population) [self initializePopulation];
    
    int popSize = [self.settings[@"Population Size"] intValue];
    
    NSAssert(popSize == self.population.count, @"Population size property and population array count are not equal");
    
    int M = [self.settings[@"Hypervolume Samples"] intValue];
    int N = (int)self.population.count;
    
    [self evaluateIndividuals:self.population]; // Implicit conditional evaluation
    if (self.shouldStop) return NO;
    
    NSMutableArray *popP = [self matingSelection:self.population count:N samples:M];
    NSMutableArray *popPP = [self variation:popP count:N];
    
    [self evaluateIndividuals:popPP]; // Implicit conditional evaluation
    if (self.shouldStop) return NO;
    
    [popPP addObjectsFromArray:self.population];
    
    self.population = [self environmentalSelection:popPP count:N samples:M];
    
    return YES;
}

- (void)reset
{
    [super reset];
    _modesCache = nil;
    _upper = nil;
    _lower = nil;
}

#pragma mark Private Methods - The HypE Algorithm

- (NSMutableArray *)matingSelection:(NSMutableArray *)population count:(int)count samples:(int)samples
{
    NSAssert(population.count > 0, @"Population size cannot be zero");
    
    [self assignFitness:population samples:samples k:(int)population.count];
    
    NSUInteger popCount = [population count];
    NSMutableArray *matingPool = [NSMutableArray array];

    while (matingPool.count < count)
    {
        YCHypEIndividual *i1 = population[arc4random_uniform((int)popCount)];
        YCHypEIndividual *i2 = population[arc4random_uniform((int)popCount)];
        
        if (i1.constraintViolation < 0 && i2.constraintViolation < 0)
        {
            if (i1.constraintViolation > i1.constraintViolation)
            {
                [matingPool addObject:i1];
            }
            else
            {
                [matingPool addObject:i2];
            }
        }
        else if (i1.constraintViolation >= 0 && i2.constraintViolation < 0)
        {
            [matingPool addObject:i1];
        }
        else if (i2.constraintViolation >= 0 && i1.constraintViolation < 0)
        {
            [matingPool addObject:i2];
        }
        else
        {
            if (i1.v < i2.v)
            {
                [matingPool addObject:i2];
            }
            else
            {
                [matingPool addObject:i1];
            }
        }
    }
    return matingPool;
}

// TODO: Here we should implement the jDE variation operator
- (NSMutableArray *)variation:(NSMutableArray *)population count:(int)count
{
    NSArray *nextGen = [self simulatedBinaryCrossoverWithPopulation:population];
    return [self polynomialMutationWithPopulation:nextGen];
}

- (NSMutableArray *)environmentalSelection:(NSMutableArray *)population count:(int)count samples:(int)samples
{
    // 1. Perform Non-Dominated Sorting
    [self nonDominatedSortingWithPopulation:population];
    
    // 2. Append each front to the new population array, and truncate
    //    the last fitting one using the individuals' hypervolume
    if (count >= [population count]) return [population copy];
    int currentRank = firstRank;
    NSMutableArray *sortedPop = [NSMutableArray array];
    while ([sortedPop count] < count)
    {
        NSMutableArray *tempPop = [NSMutableArray array];
        for (YCHypEIndividual *ind in population)
        {
            if (ind.rank == currentRank)
            {
                [tempPop addObject:ind];
            }
        }
        int totalCount = (int)([sortedPop count] + [tempPop count]);
        if (totalCount > count)
        {
            // Estimate V for the remaining individuals only!
            [self assignFitness:tempPop samples:samples k:totalCount - count];
            
            NSArray *trimmedPop = [tempPop sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                YCHypEIndividual *i1 = obj1;
                YCHypEIndividual *i2 = obj2;
                if (i1.v > i2.v)
                {
                    return NSOrderedAscending;
                }
                else if (i1.v < i2.v)
                {
                    return NSOrderedDescending;
                }
                return NSOrderedSame;
            }];
            trimmedPop = [trimmedPop subarrayWithRange:NSMakeRange(0, count - [sortedPop count])];
            [sortedPop addObjectsFromArray:trimmedPop];
        }
        else
        {
            [sortedPop addObjectsFromArray:tempPop];
        }
        currentRank++;
    }
    return sortedPop;
}

- (void)assignFitness:(NSArray *)population samples:(int)samples k:(int)k
{
    int popSize = (int)population.count;
    Matrix *fitness = [Matrix matrixOfRows:popSize columns:1];
    
    // Prepare alpha
    Matrix *alpha = [Matrix matrixOfRows:k+1 columns:1];
    
    for (int i=0; i<=k; i++)
    {
        double ai = 1.0 / (double)i;
        for (int j=1; j<=i-1; j++)
        {
            ai *= (double)(k - j)/(double)(popSize - j);
        }
        [alpha i:i j:0 set:ai];
    }
    
    // Sample the hype indicator
    NSArray *objectiveVectors = [population valueForKey:@"objectiveFunctionValues"];
    NSMutableArray *boundsVectors = [objectiveVectors mutableCopy];
    
    // Append the current upper and lower vectors, in order to include them in the
    // boundary calculation
    if (_lower) [boundsVectors addObject:_lower];
    if (_upper) [boundsVectors addObject:_upper];
    
    _lower = [boundsVectors matrixMin];
    _upper = [boundsVectors matrixMax];
    
    double volume = [[_upper matrixBySubtracting:_lower] product];
    
    Matrix *hitStat = [Matrix matrixOfRows:popSize columns:1];
    
    for (int s=0; s<samples; s++)
    {
        Matrix *sample = [Matrix uniformRandomLowerBound:_lower upperBound:_upper];
        __block int dCount = 0;
        
        for (int i=0; i<popSize; i++)
        {
            Matrix *vector = objectiveVectors[i];
            if ([[self class] vector:vector weaklyDominates:sample targets:_modesCache])
            {
                dCount++;
                if (dCount > k) break;
                [hitStat i:i j:0 set:1.0];
            }
            else
            {
                [hitStat i:i j:0 set:0.0];
            }
        }
        
        if (0 < dCount && dCount <= k)
        {
            double increment = [alpha i:dCount j:0];
            for (int i=0; i<popSize; i++)
            {
                if ([hitStat i:i j:0] == 1.0)
                {
                    [fitness i:i j:0 increment:increment];
                }
            }
        }
    }
    
    // Update individuals with fitness values
    for (int i=0; i<popSize; i++)
    {
        YCHypEIndividual *individual = population[i];
        individual.v = ([fitness i:i j:0] / (double)samples) * volume;
    }
}

+ (BOOL)vector:(Matrix *)vector weaklyDominates:(Matrix *)sample targets:(Matrix *)targets
{
    for (int i=0, n=(int)vector.count; i<n; i++)
    {
        if ([targets i:i j:0] == YCObjectiveMaximize)
        {
            // We're maximizing
            if ([vector i:i j:0] < [sample i:i j:0]) return NO;
        }
        else
        {
            // We're minimizing
            if ([vector i:i j:0] > [sample i:i j:0]) return NO;
        }
    }
    return YES;
}

// Calculates the ranks of individuals in |population|.
// This method supposes working variables are already zeroed-out beforehand.
- (void)nonDominatedSortingWithPopulation:(NSArray *)population
{
    NSArray *feasible = [population filteredArrayUsingPredicate:
                         [NSPredicate predicateWithFormat: @"self.constraintViolation >= 0"]];
    
    NSArray *infeasible = [population filteredArrayUsingPredicate:
                           [NSPredicate predicateWithFormat: @"self.constraintViolation < 0"]];
    
    NSInteger objectivesCount = 0;
    if ([feasible count])
    {
        objectivesCount = self.problem.objectiveCount;
    }
    
    int maxRank = 0;
    
    NSMutableSet *currentFront = [NSMutableSet set];
    
    Matrix *modes = self.problem.modes; // Minimize or maximize each objective?
    
    for (YCHypEIndividual *p in feasible)
    {
        p.s = [NSMutableSet set];
        p.n = 0;
        
        for (YCHypEIndividual *q in feasible)
        {
            BOOL pFlag = NO; // pp is better in one objective
            BOOL qFlag = NO; // qq is better in one objective
            
            for (int i=0; i<objectivesCount; i++)
            {
                double vp = [p.objectiveFunctionValues valueAtRow:i column:0];
                double vq = [q.objectiveFunctionValues valueAtRow:i column:0];
                if ((vp < vq && [modes i:i j:0] == 0) || (vp > vq && [modes i:i j:0] != 0))
                {
                    pFlag = YES;
                }
                else if ((vq < vp  && [modes i:i j:0] == 0) || (vq > vp  && [modes i:i j:0] != 0))
                {
                    qFlag = YES;
                }
            }
            
            if (pFlag == YES && qFlag == NO) // pp dominates qq
            {
                [p.s addObject:q];
            }
            else if (pFlag == NO && qFlag == YES) // qq dominates pp
            {
                p.n = p.n + 1;
            }
        }
        
        if (p.n == 0)
        {
            p.rank = firstRank;
            [currentFront addObject:p];
        }
    }
    
    int currentRank = firstRank;
    while ([currentFront count])
    {
        NSMutableSet *nextFront = [NSMutableSet set];
        for (YCHypEIndividual *p in currentFront)
        {
            for (YCHypEIndividual *q in p.s)
            {
                q.n = q.n - 1;
                if (q.n == 0)
                {
                    q.rank = currentRank + 1;
                    [nextFront addObject:q];
                }
            }
        }
        currentRank = currentRank + 1;
        currentFront = nextFront;
    }
    maxRank = currentRank;
    
    
    for (YCHypEIndividual *ind in infeasible)
    {
        ind.rank = maxRank;
    }
}

#pragma mark - Mutation and Crossover, carried over from NSGAII

- (NSMutableArray *)simulatedBinaryCrossoverWithPopulation:(NSArray *)population
{
    NSMutableArray *crossedOver = [NSMutableArray array];
    NSMutableArray *shuffled = [population mutableCopy];
    [shuffled shuffle];
    
    NSUInteger popCount = [shuffled count];
    int variablesCount = (int)[[shuffled[0] decisionVariableValues] count];
    double pCrossover = [self.settings[@"Crossover Probability"] doubleValue];
    double nc = [self.settings[@"NC"] doubleValue];
    
    for (int i=0; i<popCount - 1; i+=2)
    {
        YCHypEIndividual *i1 = shuffled[i];
        YCHypEIndividual *i2 = shuffled[i+1];
        
        if ( (double)arc4random() / ARC4RANDOM_MAX < pCrossover )
        {
            YCHypEIndividual *c1 = [[YCHypEIndividual alloc] initWithVariableCount:variablesCount];
            YCHypEIndividual *c2 = [[YCHypEIndividual alloc] initWithVariableCount:variablesCount];
            
            for (int j=0; j<variablesCount; j++)
            {
                double i1v = [i1.decisionVariableValues valueAtRow:j column:0];
                double i2v = [i2.decisionVariableValues valueAtRow:j column:0];
                
                if ( i1v != i2v && (double)arc4random() / ARC4RANDOM_MAX <= 0.5 )
                {
                    double xl = [self.problem.parameterBounds valueAtRow:j column:0];
                    double xu = [self.problem.parameterBounds valueAtRow:j column:1];
                    double x1 = MIN(i1v, i2v);
                    double x2 = MAX(i1v, i2v);
                    
                    double rand = (double)arc4random() / ARC4RANDOM_MAX;
                    
                    double beta = 1.0 + (2.0 * (x1 - xl) / (x2 - x1));
                    double alpha = 2.0 - pow(beta, -(nc+1));
                    double beta_q;
                    if (rand <= 1.0/alpha)
                    {
                        beta_q = pow(rand*alpha, 1.0 / (nc + 1));
                    }
                    else
                    {
                        beta_q = pow(1.0 / (2.0 - rand * alpha), 1.0 / (nc + 1));
                    }
                    double c1 = 0.5 * (x1 + x2 - beta_q * (x2 - x1));
                    
                    beta = 1.0 + (2.0 * (xu - x2) / (x2 - x1));
                    alpha = 2.0 - pow(beta, -(nc+1));
                    
                    if (rand <= 1.0/alpha)
                    {
                        beta_q = pow(rand*alpha, 1.0 / (nc + 1));
                    }
                    else
                    {
                        beta_q = pow(1.0 / (2.0 - rand * alpha), 1.0 / (nc + 1));
                    }
                    double c2 = 0.5 * (x1 + x2 + beta_q * (x2 - x1));
                    
                    c1 = MIN(MAX(c1, xl), xu);
                    c2 = MIN(MAX(c2, xl), xu);
                    
                    if ((double)arc4random() / ARC4RANDOM_MAX <= 0.5)
                    {
                        i1v = c2;
                        i2v = c1;
                    }
                    else
                    {
                        i1v = c1;
                        i2v = c2;
                    }
                }
                
                [c1.decisionVariableValues setValue:i1v row:j column:0];
                [c2.decisionVariableValues setValue:i2v row:j column:0];
            }
            c1.evaluated = NO;
            c2.evaluated = NO;
            [crossedOver addObjectsFromArray:@[c1, c2]];
        }
        else
        {
            [crossedOver addObjectsFromArray:@[[i1 copy], [i2 copy]]];
        }
    }
    return crossedOver;
}

- (NSMutableArray *)polynomialMutationWithPopulation:(NSArray *)population
{
    NSMutableArray *mutated = [NSMutableArray array];
    
    int variablesCount = (int)[[population[0] decisionVariableValues] count];
    double pMutation = [self.settings[@"Mutation Probability"] doubleValue];
    
    double nm = [self.settings[@"NM"] doubleValue];
    double indmp = [self.settings[@"Individual MP"] doubleValue];
    
    for (YCHypEIndividual *ind in population)
    {
        if ( (double)arc4random() / ARC4RANDOM_MAX < pMutation )
        {
            YCHypEIndividual *mut = [[YCHypEIndividual alloc] initWithVariableCount:variablesCount];
            
            for (int j=0; j<variablesCount; j++)
            {
                double x = [ind.decisionVariableValues valueAtRow:j column:0];
                if ( (double)arc4random() / ARC4RANDOM_MAX < indmp )
                {
                    double xl = [self.problem.parameterBounds valueAtRow:j column:0];
                    double xu = [self.problem.parameterBounds valueAtRow:j column:1];
                    
                    double delta1 = (x - xl) / (xu - xl);
                    double delta2 = (xu - x) / (xu - xl);
                    double rand = (double)arc4random() / ARC4RANDOM_MAX;
                    double mutPow = 1.0 / (nm + 1.0);
                    
                    double deltaq;
                    
                    if (rand < 0.5)
                    {
                        double xy = 1.0 - delta1;
                        double val = 2.0 * rand + (1.0 - 2.0 * rand) * pow(xy, nm + 1.0);
                        deltaq = pow(val, mutPow) - 1.0;
                    }
                    else
                    {
                        double xy = 1.0 - delta2;
                        double val = 2.0 * (1.0 - rand) + 2.0 * (rand - 0.5) * pow(xy, nm + 1);
                        deltaq = 1.0 - pow(val, mutPow);
                    }
                    
                    x = x + deltaq * (xu - xl);
                    x = MIN(MAX(x, xl), xu);
                }
                [mut.decisionVariableValues setValue:x row:j column:0];
            }
            mut.evaluated = NO;
            [mutated addObject:mut];
        }
        else
        {
            [mutated addObject:[ind copy]];
        }
    }
    return mutated;
}

@end

@implementation YCHypEIndividual

@end

@implementation NSMutableArray (Shuffling)

- (void)shuffle
{
    NSUInteger count = [self count];
    for (int i = 0; i < count; ++i)
    {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((int)remainingCount);
        [self exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

@end