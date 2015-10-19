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

#pragma mark NSCopying Implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCFFN *copy = [super copyWithZone:zone];
    if (copy)
    {
        copy.layers = [self.layers copy];
        copy.inputTransform = [self.inputTransform copy];
        copy.outputTransform = [self.outputTransform copy];
    }
    return copy;
}

#pragma mark NSCoding Implementation

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.layers forKey:@"layers"];
    [aCoder encodeObject:self.inputTransform forKey:@"inputTransform"];
    [aCoder encodeObject:self.outputTransform forKey:@"outputTransform"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.layers = [aDecoder decodeObjectForKey:@"layers"];
        self.inputTransform = [aDecoder decodeObjectForKey:@"inputTransform"];
        self.outputTransform = [aDecoder decodeObjectForKey:@"outputTransform"];
    }
    return self;
}


#pragma mark Text Description

- (NSString *)textDescription
{
    NSMutableString *description = (NSMutableString *)[super textDescription];
    [description appendFormat:@"\nActivation function is Sigmoid\n"];
    
    // Print input and output transform matrices
    if (self.inputTransform)
    {
        [description appendFormat:@"\nInput Transform (%d x %d)\nMapping Function: y = c1*x + c2\n%@",self.inputTransform.rows,
         self.inputTransform.columns, self.inputTransform];
    }
    if (self.outputTransform)
    {
        [description appendFormat:@"\nOutput Transform (%d x %d)\nMapping Function: y = c1*x + c2\n%@",self.outputTransform.rows,
         self.outputTransform.columns, self.outputTransform];
    }
    [self.layers enumerateObjectsUsingBlock:^(id  __nonnull obj, NSUInteger idx, BOOL * __nonnull stop) {
        [description appendFormat:@"\nLayers\n"];
        
        YCFullyConnectedLayer *layer = obj;
        if (self.hiddenLayerCount == 0)
        {
            [description appendFormat:@"\nInput to Output Weights (%d x %d)\n%@",layer.inputSize,
             layer.outputSize, layer.weightMatrix];
            
            [description appendFormat:@"\nInput to Output Biases (%d x 1)\n%@",layer.outputSize, layer.biasVector];
        }
        else if (idx == 0)
        {
            // Print input-hidden layer weights
            [description appendFormat:@"\nInput to H1 Weights (%d x %d)\n%@",layer.inputSize,
             layer.outputSize, layer.weightMatrix];
            
            [description appendFormat:@"\nInput to H1 Biases (%d x 1)\n%@",layer.outputSize, layer.biasVector];
        }
        else if (idx == self.hiddenLayerCount)
        {
            // Print hidden-output layer weights
            [description appendFormat:@"\nH%lu to Output Weights (%d x %d)\n%@",(unsigned long)idx,
             layer.inputSize, layer.outputSize, layer.weightMatrix];
            
            [description appendFormat:@"\nH%lu to Output Biases (%d x 1)\n%@",(unsigned long)idx,
             layer.outputSize, layer.biasVector];
        }
        else
        {
            // Print hidden-hidden layer weights
            [description appendFormat:@"\nH%lu to H%lu Weights (%d x %d)\n%@",(unsigned long)idx,
             (unsigned long)idx + 1, layer.inputSize, layer.outputSize, layer.weightMatrix];
            
            [description appendFormat:@"\nH%lu to H%lu Biases (%d x 1)\n%@",(unsigned long)idx,
             (unsigned long)idx + 1, layer.outputSize, layer.biasVector];
        }
    }];
    return description;
}

@end
