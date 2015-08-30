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
@import YCMatrix;

@implementation YCFFN

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self initFunctions];
    }
    return self;
}

- (void)initFunctions
{
    self.function = ^double(double value) {
        return 1.0 / (1.0 + exp(-value));
    };
    self.yDerivative = ^double(double value) {
        return value * (1.0 - value); // f(x) * (1 - f(x))
    };
}

- (Matrix *)activateWithMatrix:(Matrix *)matrix
{
    NSAssert([self.weightMatrices count], @"Model not trained");
    NSAssert([matrix rows] == [self.weightMatrices[0] rows], @"Input size mismatch");
    
    // 1. Scale input
    Matrix *scaledInput = matrix; // NxS
    if (self.inputTransform)
    {
        scaledInput = [matrix matrixByRowWiseMapUsing:self.inputTransform];
    }
    
    // 2. Calculate layer-by-layer (and store activations)
    NSMutableArray *lastActivations = [NSMutableArray array];
    
    Matrix *output = scaledInput;
    
    for (int i=0, j=(int)self.hiddenLayerCount; i<j; i++)
    {
        output = [self.weightMatrices[i]
                  matrixByTransposingAndMultiplyingWithRight:output]; // (HxH)T * HxS = HxS
        [output addColumn:self.biasVectors[i]];
        [output applyFunction:self.function];
        [lastActivations addObject:output];
    }
    NSUInteger outputsIndex = [self.weightMatrices count] - 1;
    output = [self.weightMatrices[outputsIndex]
              matrixByTransposingAndMultiplyingWithRight:output]; // (HxO)T * HxS = OxS
    output = [output matrixByAddingColumn:self.biasVectors[outputsIndex]];
    if (!self.linearOutputs) [output applyFunction:self.function];
    [lastActivations addObject:output];
    
    self->_lastActivations = lastActivations;
    
    // 5. Scale output and return
    if (self.outputTransform)
    {
        return [output matrixByRowWiseMapUsing:self.outputTransform];
    }
    return output;
}

- (int)inputSize
{
    return ((Matrix *)[self.weightMatrices firstObject]).rows;
}

- (int)outputSize
{
    return ((Matrix *)[self.weightMatrices lastObject]).columns;
}

- (int)hiddenLayerCount
{
    return (int)[self.weightMatrices count] - 1;
}

- (int)hiddenLayerSize
{
    return self.hiddenLayerCount ? ((Matrix *)[self.weightMatrices firstObject]).columns : 0;
}

#pragma mark NSCopying Implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCFFN *copy = [super copyWithZone:zone];
    if (copy)
    {
        copy.weightMatrices = [self.weightMatrices copy];
        copy.biasVectors = [self.biasVectors copy];
        copy->_lastActivations = [self.lastActivations copy];
        copy.inputTransform = [self.inputTransform copy];
        copy.outputTransform = [self.outputTransform copy];
        [copy setFunction:[self.function copy]];
        [copy setYDerivative:[self.yDerivative copy]];
    }
    return copy;
}

#pragma mark NSCoding Implementation

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.weightMatrices forKey:@"weightMatrices"];
    [aCoder encodeObject:self.biasVectors forKey:@"biasVectors"];
    [aCoder encodeObject:self.lastActivations forKey:@"lastActivations"];
    [aCoder encodeObject:self.inputTransform forKey:@"inputTransform"];
    [aCoder encodeObject:self.outputTransform forKey:@"outputTransform"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.weightMatrices = [aDecoder decodeObjectForKey:@"weightMatrices"];
        self.biasVectors = [aDecoder decodeObjectForKey:@"biasVectors"];
        self->_lastActivations = [aDecoder decodeObjectForKey:@"lastActivations"];
        self.inputTransform = [aDecoder decodeObjectForKey:@"inputTransform"];
        self.outputTransform = [aDecoder decodeObjectForKey:@"outputTransform"];
        [self initFunctions];
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
        [description appendFormat:@"\nInput Transform (%d x %d)\n%@",self.inputTransform.rows,
         self.inputTransform.columns, self.inputTransform];
    }
    if (self.outputTransform)
    {
        [description appendFormat:@"\nOutput Transform (%d x %d)\n%@",self.outputTransform.rows,
         self.outputTransform.columns, self.outputTransform];
    }
    [self.weightMatrices enumerateObjectsUsingBlock:^(id  __nonnull obj, NSUInteger idx, BOOL * __nonnull stop) {
        [description appendFormat:@"\nWeights\n"];
        Matrix *weights = obj;
        if (self.hiddenLayerCount == 0)
        {
            [description appendFormat:@"\nInput to Output (%d x %d)\n%@",weights.rows,
             weights.columns, weights];
        }
        else if (idx == 0)
        {
            // Print input-hidden layer weights
            [description appendFormat:@"\nInput to H1 (%d x %d)\n%@",weights.rows,
             weights.columns, weights];
        }
        else if (idx == self.hiddenLayerCount)
        {
            // Print hidden-output layer weights
            [description appendFormat:@"\nH%lu to Output (%d x %d)\n%@",(unsigned long)idx,
             weights.rows, weights.columns, weights];
        }
        else
        {
            // Print hidden-hidden layer weights
            [description appendFormat:@"\nH%lu to H%lu (%d x %d)\n%@",(unsigned long)idx,
             (unsigned long)idx + 1, weights.rows, weights.columns, weights];
        }
    }];
    [self.biasVectors enumerateObjectsUsingBlock:^(id  __nonnull obj,
                                                      NSUInteger idx,
                                                      BOOL * __nonnull stop) {
        [description appendFormat:@"\nBiases\n"];
        Matrix *biases = obj;
        if (self.hiddenLayerCount == 0)
        {
            [description appendFormat:@"\nInput to Output (%d x 1)\n%@",biases.rows, biases];
        }
        else if (idx == 0)
        {
            // Print input-hidden layer biases
            [description appendFormat:@"\nInput to H1 (%d x 1)\n%@",biases.rows, biases];
        }
        else if (idx == self.hiddenLayerCount)
        {
            // Print hidden-output layer biases
            [description appendFormat:@"\nH%lu to Output (%d x 1)\n%@",(unsigned long)idx,
             biases.rows, biases];
        }
        else
        {
            // Print hidden-hidden layer biases
            [description appendFormat:@"\nH%lu to H%lu (%d x 1)\n%@",(unsigned long)idx,
             (unsigned long)idx + 1, biases.rows, biases];
        }
    }];
    return description;
}

@end
