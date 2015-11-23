//
//  YCIndividual.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 29/6/15.
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

#define ARC4RANDOM_MAX      0x100000000

#import "YCIndividual.h"
@import YCMatrix;

@implementation YCIndividual

- (instancetype)init
{
    return [self initWithRandomValuesInBounds:[Matrix matrixOfRows:0 columns:0]];
}

- (instancetype)initWithRandomValuesInBounds:(Matrix *)bounds
{
    int m = (int)[bounds rows];
    self = [self initWithVariableCount:m];
    if (self)
    {
        for (int i=0; i<m; i++)
        {
            double min = [bounds valueAtRow:i column:0];
            double max = [bounds valueAtRow:i column:1];
            double newValue = min + ((double)arc4random() / ARC4RANDOM_MAX) * (max-min);
            [self.decisionVariableValues setValue:newValue row:i column:0];
        }
    }
    return self;
}

- (instancetype)initWithVariableCount:(int)count
{
    self = [super init];
    if (self)
    {
        self.decisionVariableValues = [Matrix matrixOfRows:count columns:1];
        self.objectiveFunctionValues = [Matrix matrixOfRows:0 columns:0];
        self.constraintValues = [Matrix matrixOfRows:0 columns:0];
        self.evaluated = NO;
    }
    return self;
}

- (double)constraintViolation
{
    return [self.constraintValues sum];
}

#pragma mark NSCopying implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCIndividual *copyOfSelf = [[[self class] alloc] init];
    copyOfSelf.decisionVariableValues = [self.decisionVariableValues copy];
    copyOfSelf.objectiveFunctionValues = [self.objectiveFunctionValues copy];
    copyOfSelf.constraintValues = [self.constraintValues copy];
    copyOfSelf.evaluated = self.evaluated;
    
    return copyOfSelf;
}

#pragma mark @"NSCoding implementation

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.decisionVariableValues = [aDecoder decodeObjectForKey:@"decisionVariableValues"];
        self.objectiveFunctionValues = [aDecoder decodeObjectForKey:@"objectiveFunctionValues"];
        self.constraintValues = [aDecoder decodeObjectForKey:@"constraintValues"];
        self.evaluated = [aDecoder decodeBoolForKey:@"evaluated"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.decisionVariableValues forKey:@"decisionVariableValues"];
    [aCoder encodeObject:self.objectiveFunctionValues forKey:@"objectiveFunctionValues"];
    [aCoder encodeObject:self.constraintValues forKey:@"constraintValues"];
    [aCoder encodeBool:self.evaluated forKey:@"evaluated"];
}

@end
