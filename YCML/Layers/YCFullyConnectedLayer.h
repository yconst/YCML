//
//  YCFullyConnectedLayer.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 11/10/15.
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

#import "YCModelLayer.h"
@class Matrix;

/**
 A densely connected feed-forward layer. This layer is not directly used 
 when building models, rather it is used as a superclass for building 
 usable layers. Does not implement an activation function.
 */
@interface YCFullyConnectedLayer : YCModelLayer

+ (instancetype)layerWithInputSize:(int)inputSize outputSize:(int)outputSize;

- (instancetype)initWithInputSize:(int)inputSize outputSize:(int)outputSize;

- (Matrix *)forward:(Matrix *)input;

- (void)activationFunction:(Matrix *)inputCopy;

- (void)activationFunctionGradient:(Matrix *)outputCopy;

- (double)regularizationLoss;

/**
 Returns the weight matrix of the receiver.
 */
@property Matrix *weightMatrix;

/**
 Returns the bias matrix of the receiver.
 */
@property Matrix *biasVector;

@property Matrix *lastActivation;

@property double L2;

@end
