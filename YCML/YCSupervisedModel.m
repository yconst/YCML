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

#pragma mark - Learner Implementation

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

- (int)inputSize
{
    return 0;
}

- (int)outputSize
{
    return 0;
}

@end

