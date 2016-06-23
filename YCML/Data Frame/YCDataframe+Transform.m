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
#import "YCMutableArray.h"
#import "OrderedDictionary.h"
#import "YCDataframe+Matrix.h"
@import YCMatrix;

#define ARC4RANDOM_MAX 0x100000000

@implementation YCDataframe (Transform)

- (instancetype)uniformSampling:(NSUInteger)count
{
    NSDictionary *stats = [self stats];
    NSArray *attributes = [stats allKeys];
    NSArray *statValues = [stats allValues];
    Matrix *mins = [Matrix matrixFromNSArray:[statValues valueForKey:@"min"]
                                         rows:(int)statValues.count
                                      columns:1] ;
    Matrix *maxs = [Matrix matrixFromNSArray:[statValues valueForKey:@"max"]
                                             rows:(int)statValues.count
                                          columns:1] ;
    
    // This will have the effect of creating a matrix using only the ordinal attributes
    // of the dataset.
    Matrix *sample = [Matrix uniformRandomLowerBound:mins upperBound:maxs count:(int)count];
    return [YCDataframe dataframeWithMatrix:sample conversionArray:attributes];
}

- (instancetype)normalSampling:(NSUInteger)count
{
    NSDictionary *stats = [self stats];
    NSArray *attributes = [stats allKeys];
    NSArray *statValues = [stats allValues];
    Matrix *means = [Matrix matrixFromNSArray:[statValues valueForKey:@"mean"]
                                         rows:(int)statValues.count
                                      columns:1] ;
    Matrix *variances = [Matrix matrixFromNSArray:[statValues valueForKey:@"variance"]
                                             rows:(int)statValues.count
                                          columns:1] ;
    
    // This will have the effect of creating a matrix using only the ordinal attributes
    // of the dataset.
    Matrix *sample = [Matrix normalRandomMean:means variance:variances count:(int)count];
    return [YCDataframe dataframeWithMatrix:sample conversionArray:attributes];
}

- (instancetype)sobolSequenceWithCount:(NSUInteger)count
{
    // TODO: This converts the dataset to a matrix first. If the dataset is large, it is wasteful.
    // try doing it another way.
    NSArray *ca = [self conversionArray];
    Matrix *m = [self getMatrixUsingConversionArray:ca];
    Matrix *mins = [m minimumsOfRows];
    Matrix *maxs = [m maximumsOfRows];
    Matrix *sequence = [Matrix sobolSequenceLowerBound:mins upperBound:maxs count:(int)count];
    return [YCDataframe dataframeWithMatrix:sequence conversionArray:ca];
}

- (instancetype)randomWalkSteps:(int)steps restarts:(int)restarts relativeStepSize:(double)stepSize
{
    YCDataframe *newDataframe = [YCDataframe dataframe];
    NSDictionary *mins = [self stat:@"min"];
    NSDictionary *maxs = [self stat:@"max"];
    NSArray *attributeKeys = [self attributeKeys];

    for (int i=0; i<restarts; i++)
    {
        NSMutableDictionary *position = [NSMutableDictionary dictionary];
        for (id key in attributeKeys)
        {
            double min = [mins[key] doubleValue];
            double max = [maxs[key] doubleValue];
            double val = ((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min;
            position[key] = @(val);
        }
        [newDataframe addSampleWithData:position];
        for (int j=1; j<steps; j++)
        {
            for (id key in attributeKeys)
            {
                double min = [mins[key] doubleValue];
                double max = [maxs[key] doubleValue];
                double val = [position[key] doubleValue];
                double range = (max - min) * stepSize;
                double newVal = val + (2 * ((double)arc4random() / ARC4RANDOM_MAX) - 1) * range;
                if (newVal > max)
                {
                    newVal -= (max - min);
                }
                else if (newVal < min)
                {
                    newVal += (max - min);
                }
                position[key] = @(newVal);
            }
            [newDataframe addSampleWithData:position];
        }
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
        if ((double)arc4random() / ARC4RANDOM_MAX > probability) continue;
        int index = arc4random_uniform((int)[attributeKeys count]);
        NSString *key = attributeKeys[index];
        double val = [self->_data[key][i] doubleValue];
        double min = [mins[key] doubleValue];
        double max = [maxs[key] doubleValue];
        double range = (max - min) * relativeMagnitude;
        double newVal = val + (2 * ((double)arc4random() / ARC4RANDOM_MAX) - 1) * range;
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
