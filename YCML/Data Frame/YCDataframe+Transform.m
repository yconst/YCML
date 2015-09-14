//
//  YCDataframe+Transform.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 24/4/15.
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

#import "YCDataframe+Transform.h"
#import "NSArray+Statistics.h"
#import "OrderedDictionary.h"

@implementation YCDataframe (Transform)

- (instancetype)randomSamplesWithCount:(int)count
{
    YCDataframe *newDataframe = [YCDataframe dataframe];
    for (NSString *key in [self attributeKeys])
    {
        NSArray *attributeData = [self allValuesForAttribute:key];
        NSMutableArray *newData = [NSMutableArray array];
        double min = [[attributeData min] doubleValue];
        double max = [[attributeData max] doubleValue];
        for (int i=0; i<count; i++)
        {
            double r = (double)arc4random() / 0x100000000;
            [newData addObject:@(r * (max - min) + min)];
        }
        [newDataframe addAttributeWithIdentifier:key data:newData];
    }
    return newDataframe;
}

- (void)corruptWithProbability:(double)probability relativeMagnitude:(double)relativeMagnitude
{
    NSDictionary *mins = [self stat:@"min"];
    NSDictionary *maxs = [self stat:@"max"];
    NSArray *attributeKeys = [self attributeKeys];
    NSUInteger count = [self dataCount];
    for (int i=0; i<count; i++)
    {
        if ((double)arc4random() / 0x100000000 > probability) continue;
        int index = arc4random_uniform((int)[attributeKeys count]);
        NSString *key = attributeKeys[index];
        double val = [self->_data[key][i] doubleValue];
        double min = [mins[key] doubleValue];
        double max = [maxs[key] doubleValue];
        double range = (max - min) * relativeMagnitude;
        double newVal = val + (2 * ((double)arc4random() / 0x100000000) - 1) * range;
        newVal = MIN(max, MAX(min, newVal));
        self->_data[key][i] = @(newVal);
    }
}

- (instancetype)dataframeByRandomSampling:(int)numberOfElements replacement:(BOOL)replacement
{
    id dataset1 = [self copy]; // This should be improved!!!
    [dataset1 removeAllSamples];
    NSUInteger dc = self.dataCount;
    if (replacement)
    {
        for (int i = 0; i < numberOfElements; i++)
        {
            NSUInteger rand = arc4random() % dc;
            [dataset1 addSampleWithData:[self sampleAtIndex:rand]];
        }
    }
    else
    {
        NSUInteger d2c = 0;
        for (NSInteger i = (int)(dc - 1); i>=0; --i)
        {
            NSUInteger p1t = numberOfElements - [dataset1 dataCount];
            NSUInteger p2t = (dc-numberOfElements) - d2c;
            int rand = arc4random() % (p1t+p2t);
            if (rand < p1t)
            {
                [dataset1 addSampleWithData:[self sampleAtIndex:i]];
            }
            else
            {
                d2c++;
            }
        }
    }
    return dataset1;
}

- (instancetype)splitByRandomSampling:(int)numberOfElements
{
    YCDataframe *dataset1 = [self copy]; // This should be improved!!!
    [dataset1 removeAllSamples];
    YCDataframe *dataset2 = [dataset1 copy];
    NSUInteger dc = self.dataCount;
    for (NSInteger i = dc - 1; i>=0; --i)
    {
        NSUInteger p1t = numberOfElements - [dataset1 dataCount];
        NSUInteger p2t = (dc-numberOfElements) - [dataset2 dataCount];
        int rand = arc4random() % (p1t+p2t);
        if (rand >= p1t)
        {
            [dataset2 addSampleWithData:[self sampleAtIndex:i]];
        }
        else
        {
            [dataset1 addSampleWithData:[self sampleAtIndex:i]];
        }
    }
    _data = dataset2->_data;
    return dataset1;
}

@end
