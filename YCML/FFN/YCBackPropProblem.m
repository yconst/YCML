//
//  YCBackPropProblem.m
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

@import YCMatrix;
#import "YCBackPropProblem.h"
#import "YCFFN.h"
#import "NSIndexSet+Sampling.h"
#import "YCFullyConnectedLayer.h"

// N: Size of input
// S: Number of samples
// H: Size of hidden layer
// O: Size of output

@implementation YCBackPropProblem

- (instancetype)initWithInputMatrix:(Matrix *)input
                       outputMatrix:(Matrix *)output
                                model:(YCFFN *)model
{
    self = [super init];
    if (self)
    {
        self->_inputMatrix = input;
        self->_outputMatrix = output;
        self->_trainedModel = model;
        self.batchSize = 1; // Default, single sample, will be probably overriden by trainer
    }
    return self;
}

- (Matrix *)initialValuesRangeHint
{
    int parameterCount = [self parameterCount];
    Matrix *minValues = [Matrix matrixOfRows:parameterCount columns:1 value:-0.1];
    Matrix *maxValues = [Matrix matrixOfRows:parameterCount columns:1 value:0.1];
    return [minValues appendColumn:maxValues];
}

- (Matrix *)parameterBounds
{
    return nil;
}

- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters
{
    NSArray *weights = [self modelWeightsWithParameters:parameters];
    NSArray *biases  = [self modelBiasesWithParameters:parameters];
    NSAssert(weights.count == self.trainedModel.layers.count, @"Weights and layers counts mismatch");
    NSAssert(biases.count == self.trainedModel.layers.count, @"Biases and layers counts mismatch");
    [self.trainedModel.layers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        YCFullyConnectedLayer *layer = obj;
        layer.weightMatrix = weights[idx];
        layer.biasVector = biases[idx];
    }];
    
    Matrix *residual = [self->_trainedModel activateWithMatrix:self->_inputMatrix];
    
    // Calculate sum-of-squares error
    [residual subtract:self->_outputMatrix];
    [residual applyFunction:^double(double value) {
        return 0.5*value*value;
    }];
    
    // Calculate regularization term
    double r = 0;
    for (YCFullyConnectedLayer *layer in self.trainedModel.layers)
    {
        r += [layer regularizationLoss];
    }
    
    // Add and return
    double s = self->_inputMatrix.columns;
    double cost = [residual sum] / (self.trainedModel.outputSize * s) + r/s;
    [target setValue:cost row:0 column:0];
}

- (void)derivatives:(Matrix *)derivatives parameters:(Matrix *)parameters
{
    // Layer numbering starts from ZERO, i.e. input layer is L0
    YCFFN *tm = self.trainedModel;
    
    // Initialization
    NSArray *weights = [self modelWeightsWithParameters:parameters];
    NSArray *biases  = [self modelBiasesWithParameters:parameters];
    NSAssert(weights.count == self.trainedModel.layers.count, @"Weights and layers counts mismatch");
    NSAssert(biases.count == self.trainedModel.layers.count, @"Biases and layers counts mismatch");
    [self.trainedModel.layers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        YCFullyConnectedLayer *layer = obj;
        layer.weightMatrix = weights[idx];
        layer.biasVector = biases[idx];
    }];
    int hiddenCount   = tm.hiddenLayerCount;
    
    // Prepare Matrices and Arrays
    int exampleCount;
    Matrix *inputMatrix;
    Matrix *outputMatrix;
    NSArray *inputMatrixArray;
    NSArray *outputMatrixArray;
    
    if (self.sampleCount <= 0 || self.sampleCount > self->_inputMatrix->columns)
    {
        // Reference & Split matrices
        exampleCount  = self->_inputMatrix->columns;
        inputMatrix  = self->_inputMatrix;
        outputMatrix = self->_outputMatrix;
        if (!self->_inputMatrixArray) _inputMatrixArray   = [inputMatrix columnWisePartition:self.batchSize];
        if (!self->_outputMatrixArray) _outputMatrixArray = [outputMatrix columnWisePartition:self.batchSize];
        inputMatrixArray = _inputMatrixArray;
        outputMatrixArray = _outputMatrixArray;
    }
    else
    {
        // Sample & Split matrices
        exampleCount  = self.sampleCount;
        NSRange range = NSMakeRange(0, self->_inputMatrix->columns);
        NSIndexSet *exampleIndexes = [NSIndexSet indexesForSampling:exampleCount
                                                            inRange:range
                                                        replacement:NO];
        inputMatrix  = [self->_inputMatrix columns:exampleIndexes];
        outputMatrix = [self->_outputMatrix columns:exampleIndexes];
        inputMatrixArray  = [inputMatrix columnWisePartition:self.batchSize];
        outputMatrixArray = [outputMatrix columnWisePartition:self.batchSize];
    }
    
    // Activate model and extract layer output arrays
    [tm activateWithMatrix:inputMatrix];
    
    NSMutableArray *activationArrays = [NSMutableArray array];
    for (Matrix *m in [tm.layers valueForKey:@"lastActivation"])
    {
        [activationArrays addObject:[m columnWisePartition:self.batchSize]];
    }
    
    // Prepare weight and bias matrices
    NSMutableArray *weightGradients = [NSMutableArray array];
    NSMutableArray *biasGradients   = [NSMutableArray array];
    for (int l=0; l<=hiddenCount; l++)
    {
        [weightGradients addObject:[Matrix matrixLike:weights[l]]];
        [biasGradients addObject:[Matrix matrixLike:biases[l]]];
    }
    
    // For every example batch:
    for (int b=0, count = (int)inputMatrixArray.count; b<count; b++)
    {
        // Calculate Deltas for Output
        NSMutableArray *deltas = [NSMutableArray array];
        Matrix *expectedOutput = outputMatrixArray[b];
        Matrix *modelOutput    = [activationArrays lastObject][b];
        
        Matrix *modelOutputGradient = [modelOutput copy];
        [[tm.layers lastObject] activationFunctionGradient:modelOutputGradient];
        
        Matrix *delta          = [modelOutput matrixBySubtracting:expectedOutput];
        [delta elementWiseMultiply:modelOutputGradient];
        
        [deltas addObject:delta];
        
        // Calculate Deltas for Hidden Layers
        for (int l=hiddenCount; l>=1; l--)
        {
            delta                   = [[tm.layers[l] weightMatrix] matrixByMultiplyingWithRight:delta];
            Matrix *layerDerivative = [activationArrays[l-1][b] copy];
            [tm.layers[l-1] activationFunctionGradient:layerDerivative];
            [delta elementWiseMultiply:layerDerivative];
            [deltas insertObject:delta atIndex:0];
        }
        
        // Find Derivatives for each weight and bias
        for (int l=0; l<=hiddenCount; l++)
        {
            Matrix *weights = [self.trainedModel.layers[l] weightMatrix];
            Matrix *incoming = l==0 ? inputMatrixArray[b] : activationArrays[l-1][b];
            delta              = deltas[l];
            Matrix *loss = [delta matrixByTransposingAndMultiplyingWithLeft:incoming];
            [loss add:[weights matrixByMultiplyingWithScalar:[self.trainedModel.layers[l] L2]]];
            [weightGradients[l] add:loss];
            
            [biasGradients[l] add:[delta sumsOfRows]];
        }
    }
    
    // Divide gradients with sample count
    double mult = 1.0/exampleCount;
    for (Matrix *m in weightGradients)
    {
        [m multiplyWithScalar:mult];
    }
    for (Matrix *m in biasGradients)
    {
        [m multiplyWithScalar:mult];
    }
    [self storeWeights:weightGradients biases:biasGradients toVector:derivatives];
}

- (NSArray *)modelWeightsWithParameters:(Matrix *)parameters
{
    double *weightsPointer = parameters->matrix;
    NSMutableArray *result = [NSMutableArray array];
    int offset = 0;
    
    for (YCFullyConnectedLayer *layer in self.trainedModel.layers)
    {
        int weightSize = (int)layer.weightMatrix.count;
        Matrix *weights = [Matrix matrixFromArray:weightsPointer+offset
                                             rows:layer.weightMatrix.rows
                                          columns:layer.weightMatrix.columns
                                             mode:YCMWeak];
        offset += weightSize;
        [result addObject:weights];
    }
    return result;
}

- (NSArray *)modelBiasesWithParameters:(Matrix *)parameters
{
    double *biasPointer    = parameters->matrix + [self weightParameterCount];
    NSMutableArray *result = [NSMutableArray array];
    int offset = 0;
    
    for (YCFullyConnectedLayer *layer in self.trainedModel.layers)
    {
        int biasSize = (int)layer.biasVector.count;
        Matrix *biases = [Matrix matrixFromArray:biasPointer+offset
                                            rows:biasSize
                                         columns:1
                                            mode:YCMWeak];
        offset += biasSize;
        [result addObject:biases];

    }
    return result;
}

- (int)weightParameterCount
{
    int sum = 0;
    for (YCFullyConnectedLayer *l in self.trainedModel.layers)
    {
        sum += l.weightMatrix.count;
    }
    return sum;
}

- (int)biasParameterCount
{
    int sum = 0;
    for (YCFullyConnectedLayer *l in self.trainedModel.layers)
    {
        sum += l.biasVector.count;
    }
    return sum;
}

- (void)storeWeights:(NSArray *)weights biases:(NSArray *)biases toVector:(Matrix *)vector
{
    // FIXME: Some really low-level shit going on here. Need to amend.
    double* parameterArray = vector->matrix;
    
    int offset = 0;
    for (Matrix *weightMatrix in weights)
    {
        NSUInteger count = [weightMatrix count];
        memcpy(&parameterArray[offset], weightMatrix->matrix, count * sizeof(double));
        offset += count;
    }
    for (Matrix *biasMatrix in biases)
    {
        NSUInteger count = [biasMatrix count];
        memcpy(&parameterArray[offset], biasMatrix->matrix, count * sizeof(double));
        offset += count;
    }
}

- (int)parameterCount
{
    return [self weightParameterCount] + [self biasParameterCount];
}

- (int)objectiveCount
{
    return 1;
}

- (int)constraintCount
{
    return 0;
}

- (Matrix *)modes
{
    return [Matrix matrixOfRows:1 columns:1 value:0];
}

- (YCEvaluationMode)supportedEvaluationMode
{
    return YCRequiresSequentialEvaluation;
}

@end
