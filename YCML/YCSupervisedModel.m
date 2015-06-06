//
//  YCSupervisedModel.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 2/3/15.
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

#import "YCSupervisedModel.h"
#import "YCDataframe.h"
#import "YCDataframe+Matrix.h"
@import YCMatrix;

@implementation YCSupervisedModel

@synthesize properties, statistics;

+ (instancetype)model
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.statistics       = [NSMutableDictionary dictionary];
        self.properties       = [NSMutableDictionary dictionary];
        self.trainingSettings = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark Learner Implementation

- (YCDataframe *)activateWithDataframe:(YCDataframe *)input
{
    Matrix *matrix = [input getMatrixUsingConversionArray:self.properties[@"InputConversionArray"]];
    Matrix *predictedMatrix = [self activateWithMatrix:matrix];
    return [YCDataframe dataframeWithMatrix:predictedMatrix
                        conversionArray:self.properties[@"OutputConversionArray"]];
}

- (Matrix *)activateWithMatrix:(Matrix *)matrix
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

#pragma mark NSCopying Implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    id copied = [[self class] model];
    if (copied)
    {
        [copied setProperties:[self.properties mutableCopy]];
        [copied setStatistics:[self.statistics mutableCopy]];
        [copied setTrainingSettings:[self.trainingSettings mutableCopy]];
    }
    return copied;
}

#pragma mark NSCoding Implementation

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.properties forKey:@"properties"];
    [encoder encodeObject:self.statistics forKey:@"statistics"];
    [encoder encodeObject:self.trainingSettings forKey:@"trainingSettings"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        self.properties = [decoder decodeObjectForKey:@"properties"];
        self.statistics = [decoder decodeObjectForKey:@"statistics"];
        self.trainingSettings = [decoder decodeObjectForKey:@"trainingSettings"];
    }
    return self;
}

- (int)inputSize
{
    return 0;
}

- (int)outputSize
{
    return 0;
}

@end

