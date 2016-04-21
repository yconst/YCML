//
//  FFNModel.m
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


// N: Size of input
// S: Number of samples
// H: Size of hidden layer
// O: Size of output

/*
 * Guidelines for matrix sizing
 * Input: Should be arranged so that every *sample* is a *column*
 * Input: NxS
 *
 * Weights:
 * For every layer n: Let C be the current layer's size, T the next layers size.
 * The weights from n to n+1 form a matrix of dimensions CxT (current layer units as columns)
 * In order to derive the next layer's z, the output of n is left-multipled with
 * the transpose of the weights from n to n+1:
 * zn+1 = Wn^T * an
 */

#import "YCFFN.h"
#import "YCFullyConnectedLayer.h"
@import YCMatrix;

@implementation YCFFN

- (Matrix *)activateWithMatrix:(Matrix *)matrix
{
    NSAssert([self.layers count], @"Model not trained");
    NSAssert([matrix rows] == self.inputSize, @"Input size mismatch");
    
    // 1. Scale input
    Matrix *scaledInput = matrix; // NxS
    if (self.inputTransform)
    {
        scaledInput = [matrix matrixByRowWiseMapUsing:self.inputTransform];
    }
    
    // 2. Calculate layer-by-layer
    
    Matrix *output = scaledInput;
    
    for (int i=0, j=(int)[self.layers count]; i<j; i++)
    {
        output = [self.layers[i] forward:output];
    }
    
    // 5. Scale output and return
    if (self.outputTransform)
    {
        return [output matrixByRowWiseMapUsing:self.outputTransform];
    }
    return output;
}

- (int)inputSize
{
    return ((YCFullyConnectedLayer *)[self.layers firstObject]).inputSize;
}

- (int)outputSize
{
    return ((YCFullyConnectedLayer *)[self.layers lastObject]).outputSize;
}

- (int)hiddenLayerCount
{
    return (int)[self.layers count] - 1;
}

@end
