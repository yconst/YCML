//
//  NSArray+Statistics.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 29/3/15.
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

#import "NSArray+Statistics.h"
#import "NSIndexSet+Sampling.h"

@implementation NSArray (Statistics)

- (NSArray *)sample:(int)samples replacement:(BOOL)replacement
{
    NSRange theRange = NSMakeRange(0, self.count);
    NSIndexSet *theIndexes = [NSIndexSet indexesForSampling:samples
                                                    inRange:theRange
                                                replacement:replacement];
    return [self objectsAtIndexes:theIndexes];
}

- (NSDictionary *)stats
{
    NSArray *statOperations = @[@"sum", @"min", @"max", @"mean", @"median", @"variance"];
    NSMutableDictionary *attributeStats = [NSMutableDictionary dictionary];
    for (NSString *op in statOperations)
    {
        [attributeStats setObject:[self calculateStat:op]
                           forKey:op];
    }
    [attributeStats setObject:@(sqrt([attributeStats[@"variance"] doubleValue])) forKey:@"sd"];
    return attributeStats;
}

- (NSNumber *)calculateStat:(NSString *)stat
{
    if ([stat isEqualToString:@"sum"])
    {
        return [self sum];
    }
    else if ([stat isEqualToString:@"min"])
    {
        return [self min];
    }
    else if ([stat isEqualToString:@"max"])
    {
        return [self max];
    }
    else if ([stat isEqualToString:@"mean"] || [stat isEqualToString:@"average"])
    {
        return [self mean];
    }
    else if ([stat isEqualToString:@"median"])
    {
        return [self median];
    }
    else if ([stat isEqualToString:@"variance"])
    {
        return [self variance];
    }
    else if ([stat isEqualToString:@"sd"])
    {
        return [self sd];
    }
    return nil;
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

- (NSNumber *)sum
{
    return [self valueForKeyPath:@"@sum.self"];
}

- (NSNumber *)min
{
    return [self valueForKeyPath:@"@min.self"];
}

- (NSNumber *)max
{
    return [self valueForKeyPath:@"@max.self"];
}

- (NSNumber *)mean
{
    return [self valueForKeyPath:@"@avg.self"];
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
    double mean = [[self mean] doubleValue];
    double meanDifferencesSum = 0;
    for (NSNumber *score in self)
    {
        meanDifferencesSum += pow(([score doubleValue] - mean), 2);
    }
    
    NSNumber *variance = @(meanDifferencesSum / self.count);
    
    return variance;
}

- (NSNumber *)sd
{
    return @(sqrt([[self variance] doubleValue]));
}

@end
