//
//  YCNSGAII.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 2/3/15.
//  Copyright (c) 2015-2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

// References for this document:
// http://www.iitk.ac.in/kangal/codes.shtml
// http://stackoverflow.com/questions/56648/whats-the-best-way-to-shuffle-an-nsmutablearray

#define ARC4RANDOM_MAX      0x100000000
#define firstRank           1

#import "YCNSGAII.h"
@import YCMatrix;

@interface NSMutableArray (Shuffling)

- (void)shuffle;

@end

@implementation YCNSGAII

+ (Class)individualClass
{
    return [YCNSGAIndividual class];
}

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem settings:(NSDictionary *)settings
{
    self = [super initWithProblem:aProblem settings:settings];
    if (self)
    {
        self.settings[@"Crossover Probability"] = @0.9;
        self.settings[@"Mutation Probability"] = @0.2;
        self.settings[@"NC"] = @10.0;
        self.settings[@"NM"] = @30.0;
        self.settings[@"Individual MP"] = @0.5;
    }
    return self;
}

- (BOOL)iterate:(int)iteration
{
    if (!self.population) [self initializePopulation];
    int popSize = [self.settings[@"Population Size"] intValue];
    
    NSAssert(popSize == self.population.count, @"Population size property and population array count are not equal");
    
    [self evaluateIndividuals:self.population]; // Implicit conditional evaluation
    if (self.shouldStop) return NO;
    
    [self nonDominatedSortingWithPopulation:self.population];
    [self crowdingDistanceCalculationWithPopulation:self.population];
    
    NSArray *matingPool = [self tournamentSelectionWithPopulation:self.population];
    NSArray *nextGen = [self simulatedBinaryCrossoverWithPopulation:matingPool];
    nextGen = [self polynomialMutationWithPopulation:nextGen];
    
    [self evaluateIndividuals:nextGen]; // Implicit conditional evaluation
    if (self.shouldStop) return NO;
    
    NSMutableArray *combined = [nextGen mutableCopy];
    [combined addObjectsFromArray:self.population];
    
    [self nonDominatedSortingWithPopulation:combined];
    [self crowdingDistanceCalculationWithPopulation:combined];
    
    self.population = [self reduce:combined ToSize:popSize];
    
    return YES;
}

#pragma mark - The NSGA-II Algorithm

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
    
    for (YCNSGAIndividual *p in feasible)
    {
        p.s = [NSMutableSet set];
        p.n = 0;
        
        for (YCNSGAIndividual *q in feasible)
        {
            BOOL pFlag = NO; // pp is better in one objective
            BOOL qFlag = NO; // qq is better in one objective
            
            for (int i=0; i<objectivesCount; i++)
            {
                double vp = [p.objectiveFunctionValues valueAtRow:i column:0];
                double vq = [q.objectiveFunctionValues valueAtRow:i column:0];
                if ((vp < vq && [modes i:i j:0] == YCObjectiveMinimize) ||
                    (vp > vq && [modes i:i j:0] == YCObjectiveMaximize))
                {
                    pFlag = YES;
                }
                else if ((vq < vp  && [modes i:i j:0] == YCObjectiveMinimize) ||
                         (vq > vp  && [modes i:i j:0] == YCObjectiveMaximize))
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
        for (YCNSGAIndividual *p in currentFront)
        {
            for (YCNSGAIndividual *q in p.s)
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

    
    for (YCNSGAIndividual *ind in infeasible)
    {
        ind.rank = maxRank;
    }
}

// Calculates the rank-wise crowding distance for individuals in |aPopulation|.
// This method supposes working variables are already zeroed-out beforehand.
// WARNING:
// During the sorting of the individuals maximization/minimization preference
// is not taken into account for setting order. This should be ok normally, but
// it remains to be verified.
- (void)crowdingDistanceCalculationWithPopulation:(NSArray *)aPopulation
{
    int maxRank = 0;
    NSUInteger objectiveCount = self.problem.objectiveCount;
    
    for (YCNSGAIndividual *ind in aPopulation)
    {
        maxRank = MAX(maxRank, ind.rank);
        ind.crowdingDistance = 0;
    }
    
    NSMutableArray *fronts = [NSMutableArray array];
    for (int i=0; i<maxRank; i++)
    {
        [fronts addObject:[NSMutableArray array]];
    }
    
    for (YCNSGAIndividual *ind in aPopulation)
    {
        [fronts[ind.rank - 1] addObject:ind];
    }
    
    for (NSArray *front in fronts)
    {
        NSUInteger frontCount = [front count];
        
        for (int i=0; i<objectiveCount; i++)
        {
            NSArray *sortedFront = [front sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                double v1 = [[obj1 objectiveFunctionValues] valueAtRow:i column:0];
                double v2 = [[obj2 objectiveFunctionValues] valueAtRow:i column:0];
                if (v1 < v2)
                {
                    return NSOrderedAscending;
                }
                else if (v1 > v2)
                {
                    return NSOrderedDescending;
                }
                return NSOrderedSame;
            }];
            
            [[sortedFront firstObject] setCrowdingDistance:DBL_MAX];
            [[sortedFront lastObject] setCrowdingDistance:DBL_MAX];
            
            for (int j=1; j <frontCount-1; j++)
            {
                double newCD = [sortedFront[j] crowdingDistance];
                newCD += fabs([[sortedFront[j-1] objectiveFunctionValues] valueAtRow:i column:0] -
                             [[sortedFront[j+1] objectiveFunctionValues] valueAtRow:i column:0]);
                [sortedFront[j] setCrowdingDistance:newCD];
            }
        }
    }
    
    for (YCNSGAIndividual *ind in aPopulation)
    {
        ind.crowdingDistance /= objectiveCount;
    }
}

- (NSMutableArray *)tournamentSelectionWithPopulation:(NSArray *)population
{
    NSAssert(population.count > 0, @"Population size cannot be zero");
    
    NSUInteger popCount = [population count];

    NSMutableArray *matingPool = [NSMutableArray array];
    for (YCNSGAIndividual *i1 in population)
    {
        int randomIndex = arc4random_uniform((int)popCount);
        YCNSGAIndividual *i2 = population[randomIndex];
        
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
            if (i1.rank < i2.rank)
            {
                [matingPool addObject:i1];
            }
            else if (i1.rank > i2.rank)
            {
                [matingPool addObject:i2];
            }
            else
            {
                if (i1.crowdingDistance > i2.crowdingDistance)
                {
                    [matingPool addObject:i1];
                }
                else if (i1.crowdingDistance < i2.crowdingDistance)
                {
                    [matingPool addObject:i2];
                }
                else if ((double)arc4random() / ARC4RANDOM_MAX < 0.5)
                {
                    [matingPool addObject:i1];
                }
                else
                {
                    [matingPool addObject:i2];
                }
            }
        }
    }
    return matingPool;
}

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
        YCNSGAIndividual *i1 = shuffled[i];
        YCNSGAIndividual *i2 = shuffled[i+1];
        
        if ( (double)arc4random() / ARC4RANDOM_MAX < pCrossover )
        {
            YCNSGAIndividual *c1 = [[YCNSGAIndividual alloc] initWithVariableCount:variablesCount];
            YCNSGAIndividual *c2 = [[YCNSGAIndividual alloc] initWithVariableCount:variablesCount];
            
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
    
    for (YCNSGAIndividual *ind in population)
    {
        if ( (double)arc4random() / ARC4RANDOM_MAX < pMutation )
        {
            YCNSGAIndividual *mut = [[YCNSGAIndividual alloc] initWithVariableCount:variablesCount];
            
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

- (NSMutableArray *)reduce:(NSArray *)population ToSize:(int)size
{
    if (size >= [population count]) return [population copy];
    int currentRank = firstRank;
    NSMutableArray *sortedPop = [NSMutableArray array];
    while ([sortedPop count] < size)
    {
        NSMutableArray *tempPop = [NSMutableArray array];
        for (YCNSGAIndividual *ind in population)
        {
            if (ind.rank == currentRank)
            {
                [tempPop addObject:ind];
            }
        }
        if ([sortedPop count] + [tempPop count] > size)
        {
            NSArray *trimmedPop = [tempPop sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                YCNSGAIndividual *i1 = obj1;
                YCNSGAIndividual *i2 = obj2;
                if (i1.crowdingDistance > i2.crowdingDistance)
                {
                    return NSOrderedAscending;
                }
                else if (i1.crowdingDistance < i2.crowdingDistance)
                {
                    return NSOrderedDescending;
                }
                return NSOrderedSame;
            }];
            trimmedPop = [trimmedPop subarrayWithRange:NSMakeRange(0, size - [sortedPop count])];
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

@end

@implementation YCNSGAIndividual

- (instancetype)initWithRandomValuesInBounds:(Matrix *)bounds
{
    self = [super initWithRandomValuesInBounds:bounds];
    if (self)
    {
        self.rank = INT_MAX;
        self.crowdingDistance = 0;
        self.n = 0;
        self.s = [NSMutableSet set];
    }
    return self;
}

#pragma mark NSCopying implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCNSGAIndividual *copyOfSelf = [super copyWithZone:zone];
    copyOfSelf.rank = self.rank;
    copyOfSelf.crowdingDistance = self.crowdingDistance;
    copyOfSelf.n = self.n;
    copyOfSelf.s = [self.s copy];
    
    return copyOfSelf;
}

#pragma mark NSCoding implementation

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.rank = [aDecoder decodeIntForKey:@"rank"];
        self.crowdingDistance = [aDecoder decodeDoubleForKey:@"crowdingDistance"];
        self.s = [NSMutableSet set]; // Do not decode n and s!
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInt:self.rank forKey:@"rank"];
    [aCoder encodeDouble:self.crowdingDistance forKey:@"crowdingDistance"];
    // Do not encode n and s!
}

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