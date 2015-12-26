//
//  YCBackPropProblem.h
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

@import Foundation;
#import "YCDerivativeProblem.h"

@class YCFFN;

@interface YCBackPropProblem : NSObject <YCDerivativeProblem>
{
    Matrix *_inputMatrix;
    NSArray *_inputMatrixArray;
    Matrix *_outputMatrix;
    NSArray *_outputMatrixArray;
}

- (instancetype)initWithInputMatrix:(Matrix *)input
                       outputMatrix:(Matrix *)output
                              model:(YCFFN *)model;

- (NSArray *)modelWeightsWithParameters:(Matrix *)parameters;

- (NSArray *)modelBiasesWithParameters:(Matrix *)parameters;

- (void)storeWeights:(NSArray *)weights biases:(NSArray *)biases toVector:(Matrix *)vector;

@property YCFFN *trainedModel;

@property int sampleCount;

@property int batchSize;

@end
