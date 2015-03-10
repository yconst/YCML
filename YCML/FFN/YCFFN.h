//
//  FFNModel.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 2/3/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
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

@interface YCFFN : YCSupervisedModel

/**
 Returns an array of matrices corresponding to the weights of the receiver.
 */
@property NSArray *weightMatrices;

/**
 Returns an array of matrices corresponding to the biases of the receiver.
 */
@property NSArray *biasVectors;

/**
 Returns the input transformation matrix of the receiver.
 */
@property (strong) YCMatrix *inputTransform;

/**
 Returns the output reverse transformation matrix of the receiver.
 */
@property (strong) YCMatrix *outputTransform;

/**
 Returns the receiver's input size.
 */
@property (readonly) int inputSize;

/**
 Returns the receiver's output size.
 */
@property (readonly) int outputSize;

@property BOOL linearOutputs;

/**
 Returns the number of hidden layers of the receiver.
 */
@property (readonly) int hiddenLayerCount;

/**
 Returns the size of the hidden layers of the receiver.
 */
@property (readonly) int hiddenLayerSize;

/**
 Returns the activation function of the receiver.
 */
@property (copy) double (^function)(double value);

/**
 Returns the derivative of the activation function of
 the receiver, with respect to the function value (y).
 */
@property (copy) double (^yDerivative)(double value);

/**
 Returns a cache of the last values produced from activating 
 each layer of the receiver.
 */
@property (readonly) NSArray *lastActivations;

@end
