//
//  NSIndexSet+Sampling.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 1/7/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import "NSIndexSet+Sampling.h"

#define ARC4RANDOM_MAX      0x100000000

@implementation NSIndexSet (Sampling)

+ (instancetype)indexesForSampling:(int)samples inRange:(NSRange)range replacement:(BOOL)replacement
{
    NSMutableIndexSet *selectedIndexes = [NSMutableIndexSet indexSet];
    if (replacement)
    {
        NSUInteger N = range.length;
        for (int i=0; i<samples; i++)
        {
            [selectedIndexes addIndex:range.location + (int)(N * (double)arc4random() / ARC4RANDOM_MAX)];
        }
    }
    else
    {
        int i = 0;
        int n = samples;
        NSUInteger N = range.length;
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
