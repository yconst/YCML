//
//  NSIndexSet+Sampling.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 1/7/15.
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

#import "NSIndexSet+Sampling.h"

#define ARC4RANDOM_MAX      0x100000000

@implementation NSIndexSet (Sampling)

+ (instancetype)indexesForSampling:(NSUInteger)samples inRange:(NSRange)range replacement:(BOOL)replacement
{
    NSMutableIndexSet *selectedIndexes = [NSMutableIndexSet indexSet];
    if (replacement)
    {
        NSUInteger N = range.length;
        for (NSUInteger i=0; i<samples; i++)
        {
            [selectedIndexes addIndex:range.location + (int)(N * (double)arc4random() / ARC4RANDOM_MAX)];
        }
    }
    else
    {
        NSUInteger N = range.length;
        NSUInteger i = 0;
        NSUInteger n = MIN(N, samples);
        while (n > 0)
        {
            if (N * (double)arc4random() / ARC4RANDOM_MAX <= n)
            {
                [selectedIndexes addIndex:range.location + i];
                n--;
            }
            i++;
            N--;
        }
    }
    return selectedIndexes;
}

@end
