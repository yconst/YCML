//
//  YCMutableArray.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 18/4/16.
//  Copyright © 2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

#import "YCMutableArray.h"
#import "NSIndexSet+Sampling.h"
#import "YCMatrix.h"

@implementation Stats
{
    double _sum;
    double _mean;
    double _min;
    double _max;
    double _variance;
    double _sd;
}

- (instancetype)initWithArray:(NSArray *)array
{
    self = [super init];
    if (self)
    {
        [self updateStatsWithArray:array];
    }
    return self;
}

- (void)updateStatsWithArray:(NSArray *)array
{
    NSUInteger n = array.count;
    
    NSUInteger c = 0;
    double mean = 0.0;
    double M2 = 0.0;
    
    double sum = 0;
    double min = DBL_MAX;
    double max = -DBL_MAX;
    
    for (id nsn in array)
    {
        if ([nsn isKindOfClass:[NSNumber class]])
        {
            c++;
            
            double x = [nsn doubleValue];
            sum += x;
            
            double delta = x - mean;
            mean += delta/c;
            M2 += delta*(x - mean);
            
            if (x<min) min = x;
            if (x>max) max = x;
        }
    }
    
    _min = min;
    _max = max;
    _sum = sum;
    _mean = mean;
    _variance = c>0 ? M2/n : 0;
    _sd = sqrt(_variance);
    
    if (_min > _max)
    {
        // Array is empty or something else has gone wrong (e.g. no numerical values)
        // This is kind of a quick workaround.
        // TODO: Revise/refactor with more robust solution.
        _min = 0;
        _max = 0;
        _mean = 0;
        _sum = 0;
        _variance = 0;
        _sd = 0;
    }
}

@end

@implementation YCMutableArray
{
    NSMutableArray *_backing;
    Stats *_stats;
    YCMutableArray *_bins;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _backing = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self)
    {
        _backing = [[NSMutableArray alloc] initWithCapacity:numItems];
    }
    return self;
}

#pragma mark - NSArray Implementation

- (NSUInteger)count
{
    return [_backing count];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [_backing objectAtIndex:index];
}

#pragma mark - NSMutableArray Implementation

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    _stats = nil;
    _bins = nil;
    [_backing insertObject:anObject atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    _stats = nil;
    _bins = nil;
    [_backing removeObjectAtIndex:index];
}

- (void)addObject:(id)anObject
{
    _stats = nil;
    _bins = nil;
    [_backing addObject:anObject];
}

- (void)removeLastObject
{
    _stats = nil;
    _bins = nil;
    [_backing removeLastObject];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    _stats = nil;
    _bins = nil;
    [_backing replaceObjectAtIndex:index withObject:anObject];
}

#pragma mark - NSCopying Implementation

- (id)copy
{
    return [_backing copy];
}

- (id)mutableCopy
{
    return [YCMutableArray arrayWithArray:_backing];
}

#pragma mark - Interface Implementation

- (NSArray *)sample:(int)samples replacement:(BOOL)replacement
{
    NSRange theRange = NSMakeRange(0, self.count);
    NSIndexSet *theIndexes = [NSIndexSet indexesForSampling:samples
                                                    inRange:theRange
                                                replacement:replacement];
    return [self objectsAtIndexes:theIndexes];
}

- (NSIndexSet *)indexesOfOutliersWithFenceMultiplier:(double)multiplier
{
    NSAssert(multiplier > 0, @"Zero or negative fence multiplier");
    double Q1 = [self.Q1 doubleValue];
    double Q3 = [self.Q3 doubleValue];
    double iql = Q3 - Q1;
    double lf = Q1 - iql * multiplier;
    double hf = Q3 + iql * multiplier;
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger count = 0;
    for (NSNumber *n in self)
    {
        double dn = [n doubleValue];
        if (dn < lf || dn > hf)
        {
            [indexes addIndex:count];
        }
        count++;
    }
    return indexes;
}

- (NSNumber *)quantile:(double)q
{
    NSAssert(0 <= q && q <= 1, @"Quantile value beyond range");
    NSAssert(self.count > 0, @"Array is empty");
    NSArray *sortedArray = [self sortedArrayUsingSelector:@selector(compare:)];
    
    if (q == 1) return [sortedArray lastObject];
    
    double realIndex = ((double)[sortedArray count] + 1.0) * q;
    int lastIndex = (int)self.count - 1;
    int firstIndex = MIN(MAX(0, (int)realIndex), lastIndex);
    int secondIndex = MIN(firstIndex + 1, lastIndex);
    double ratio = realIndex - firstIndex;
    double v1 = [sortedArray[firstIndex] doubleValue];
    double v2 = [sortedArray[secondIndex] doubleValue];
    return @(v1 * (1-ratio) + v2 * ratio);
}

- (YCMutableArray *)bins:(NSUInteger)numberOfBins
{
    if (_bins && _bins.count == numberOfBins) return _bins;
    
    double min = [self.min doubleValue];
    double range = [self.max doubleValue] - min;
    
    if (range <= 0)
    {
        self->_bins = [YCMutableArray arrayWithArray:@[@1]];
    }
    else
    {
        double step = range / (double)(numberOfBins);
        
        Matrix *binValues = [Matrix matrixOfRows:(int)numberOfBins columns:1];
        
        for (id val in self)
        {
            if ([val isKindOfClass:[NSNumber class]])
            {
                NSNumber *n = val;
                int index = MIN((int)numberOfBins - 1, (int)(([n doubleValue] - min) / step));
                [binValues i:index j:0 increment:1];
            }
        }
        
        self->_bins = [YCMutableArray arrayWithArray:[binValues numberArray]];
    }
    return self->_bins;
}


#pragma mark - Accessors

- (NSNumber *)sum
{
    return @(self.stats.sum);
}

- (NSNumber *)min
{
    return @(self.stats.min);
}

- (NSNumber *)max
{
    return @(self.stats.max);
}

- (NSNumber *)mean
{
    return @(self.stats.mean);
}

- (NSNumber *)Q1
{
    return [self quantile:0.25];
}

- (NSNumber *)median
{
    return [self quantile:0.5];
}

- (NSNumber *)Q3
{
    return [self quantile:0.75];
}

- (NSNumber *)variance
{
    return @(self.stats.variance);
}

- (NSNumber *)sd
{
    return @(self.stats.sd);
}

- (Stats *)stats
{
    if (!_stats)
    {
        _stats = [[Stats alloc] initWithArray:self];
    }
    return _stats;
}

- (YCMutableArray *)bins
{
    if (!_bins)
    {
        [self bins:10];
    }
    return _bins;
}

// No KVO compliance by default, so we'll have to implement it.
- (id)valueForKey:(NSString *)key
{
    if ([key isEqualToString:@"sum"])
    {
        return self.sum;
    }
    else if ([key isEqualToString:@"min"])
    {
        return self.min;
    }
    else if ([key isEqualToString:@"max"])
    {
        return self.max;
    }
    else if ([key isEqualToString:@"mean"])
    {
        return self.mean;
    }
    else if ([key isEqualToString:@"Q1"])
    {
        return self.Q1;
    }
    else if ([key isEqualToString:@"median"])
    {
        return self.median;
    }
    else if ([key isEqualToString:@"Q3"])
    {
        return self.Q3;
    }
    else if ([key isEqualToString:@"variance"])
    {
        return self.variance;
    }
    else if ([key isEqualToString:@"sd"])
    {
        return self.sd;
    }
    else if ([key isEqualToString:@"bins"])
    {
        return self.bins;
    }
    return nil;
}

@end
