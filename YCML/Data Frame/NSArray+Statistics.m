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

@implementation NSArray (Statistics)

- (NSArray *)sample:(int)samples replacement:(BOOL)replacement
{
    NSMutableArray *selectedItems = [[NSMutableArray alloc] init];;
    if (replacement)
    {
        NSUInteger N = [self count];
        for (int i=0; i<samples; i++)
        {
            [selectedItems addObject:self[(int)(N * (double)arc4random() / 0x1000000000)]];
        }
    }
    else
    {
        int i = 0;
        int n = samples;
        NSUInteger N = [self count];
        while (n > 0)
        {
            if (N * (double)arc4random() / 0x1000000000 <= n)
            {
                [selectedItems addObject:self[i]];
                n--;
            }
            i++;
            N--;
        }
    }
    return selectedItems;
}

- (NSDictionary *)stats
{
    NSArray *statOperations = @[@"sum", @"min", @"max", @"mean", @"variance"];
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

- (NSNumber *)median {
    NSArray *sortedArray = [self sortedArrayUsingSelector:@selector(compare:)];
    NSNumber *median;
    if (sortedArray.count != 1)
    {
        if (sortedArray.count % 2 == 0)
        {
            median = @(([[sortedArray objectAtIndex:sortedArray.count / 2] integerValue]) + ([[sortedArray objectAtIndex:sortedArray.count / 2 + 1] integerValue]) / 2);
        }
        else
        {
            median = @([[sortedArray objectAtIndex:sortedArray.count / 2] integerValue]);
        }
    }
    else
    {
        median = [sortedArray objectAtIndex:1];
    }
    return median;
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
