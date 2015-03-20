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
    }
    return self;
}

- (Matrix *)initialValuesRangeHint
{
    int parameterCount = [self parameterCount];
    Matrix *minValues = [Matrix matrixOfRows:parameterCount Columns:1 Value:-0.1];
    Matrix *maxValues = [Matrix matrixOfRows:parameterCount Columns:1 Value:0.1];
    return [minValues appendColumn:maxValues];
}

- (Matrix *)parameterBounds
{
    return nil;
}

- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters
{
    self.trainedModel.weightMatrices = [self modelWeightsWithParameters:parameters];
    self.trainedModel.biasVectors    = [self modelBiasesWithParameters:parameters];
    Matrix *residual               = [self->_trainedModel activateWithMatrix:self->_inputMatrix];
    
    // calculate sum-of-squares error
    [residual subtract:self->_outputMatrix];
    [residual applyFunction:^double(double value) {
        return 0.5*value*value;
    }];
    
    // calculate regularization term
    int n = self->_outputMatrix->columns;
    int s = self->_outputMatrix->rows;
    Matrix *weights = [parameters matrixWithRowsInRange:NSMakeRange(0, [self weightParameterCount])];
    [weights elementWiseMultiply:weights];
    double ws2 = [weights sum];
    
    // add and return
    double cost = [residual sum] / (n * s) + self.lambda * ws2/n;
    [target setValue:cost Row:0 Column:0];
}

- (void)derivatives:(Matrix *)derivatives parameters:(Matrix *)parameters
{
    // Layer numbering starts from ZERO, i.e. input layer is L0
    YCFFN *tm = self.trainedModel;
    
    // Initialization
    tm.weightMatrices = [self modelWeightsWithParameters:parameters];
    tm.biasVectors    = [self modelBiasesWithParameters:parameters];
    int hiddenCount   = tm.hiddenLayerCount;
    int sampleCount   = self->_inputMatrix->columns;
    
    // Split matrices
    if (!self->_inputMatrixArray) _inputMatrixArray   = [_inputMatrix ColumnsAsNSArray];
    if (!self->_outputMatrixArray) _outputMatrixArray = [_outputMatrix ColumnsAsNSArray];
    
    [tm activateWithMatrix:self->_inputMatrix];
    
    NSMutableArray *activationArrays = [NSMutableArray array];
    for (Matrix *m in [tm lastActivations])
    {
        [activationArrays addObject:[m ColumnsAsNSArray]];
    }
    
    NSMutableArray *weightGradients = [NSMutableArray array];
    NSMutableArray *biasGradients   = [NSMutableArray array];
    for (int l=0; l<=hiddenCount; l++)
    {
        [weightGradients addObject:[Matrix matrixLike:tm.weightMatrices[l]]];
        [biasGradients addObject:[Matrix matrixLike:tm.biasVectors[l]]];
    }
    
    for (int s=0; s<sampleCount; s++)
    {
        // Calculate Deltas for Output
        NSMutableArray *deltas = [NSMutableArray array];
        Matrix *expectedOutput = _outputMatrixArray[s];
        Matrix *modelOutput    = [activationArrays lastObject][s];
        Matrix *delta          = [modelOutput matrixBySubtracting:expectedOutput];
        [delta elementWiseMultiply:[modelOutput matrixByApplyingFunction:tm.yDerivative]];
        
        [deltas addObject:delta];
        
        // Calculate Deltas for Hidden Layers
        for (int l=hiddenCount; l>=1; l--)
        {
            delta                     = [tm.weightMatrices[l] matrixByMultiplyingWithRight:delta];
            Matrix *layerDerivative = [activationArrays[l-1][s] matrixByApplyingFunction:tm.yDerivative];
            [delta elementWiseMultiply:layerDerivative];
            [deltas insertObject:delta atIndex:0];
        }
        
        // Find Derivatives for each weight and bias
        for (int l=0; l<=hiddenCount; l++)
        {
            Matrix *weights = self.trainedModel.weightMatrices[l];
            Matrix *incoming = l==0 ? _inputMatrixArray[s] : activationArrays[l-1][s];
            delta              = deltas[l];
            Matrix *loss = [delta matrixByTransposingAndMultiplyingWithLeft:incoming];
            [loss add:[weights matrixByMultiplyingWithScalar:self.lambda]];
            [weightGradients[l] add:loss];
            
            [biasGradients[l] add:delta];
        }
    }
    double mult = 1.0/sampleCount;
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
    YCFFN *tm              = self.trainedModel;
    int hlSize             = tm.hiddenLayerSize;
    int hlCount            = tm.hiddenLayerCount;
    int inputSize          = tm.inputSize;
    int outputSize         = tm.outputSize;
    
    // TODO: Handle case of no hidden layer
    
    Matrix *inputToHidden = [Matrix matrixFromArray:weightsPointer
                                                   Rows:inputSize
                                                Columns:hlSize
                                                   Mode:YCMWeak]; //  NxH
    [result addObject:inputToHidden];
    int stride = (int)inputToHidden.count;
    for (int i=0; i<hlCount-1; i++)
    {
        Matrix *hiddenToHidden = [Matrix matrixFromArray:weightsPointer+stride
                                                        Rows:hlSize
                                                     Columns:hlSize
                                                        Mode:YCMWeak]; // HxH
        [result addObject:hiddenToHidden];
        stride += (int)hiddenToHidden.count;
    }
    Matrix *hiddenToOutput = [Matrix matrixFromArray:weightsPointer+stride
                                                    Rows:hlSize
                                                 Columns:outputSize
                                                    Mode:YCMWeak]; // HxO
    [result addObject:hiddenToOutput];
    return result;
}

- (NSArray *)modelBiasesWithParameters:(Matrix *)parameters
{
    double *biasPointer    = parameters->matrix + [self weightParameterCount];
    NSMutableArray *result = [NSMutableArray array];
    int hlSize             = self.trainedModel.hiddenLayerSize;
    int hlCount            = self.trainedModel.hiddenLayerCount;
    int outputSize         = self.trainedModel.outputSize;
    
    // TODO: Handle case of no hidden layer
    
    Matrix *inputToHidden = [Matrix matrixFromArray:biasPointer
                                                   Rows:hlSize
                                                Columns:1
                                                   Mode:YCMWeak]; // Hx1
    [result addObject:inputToHidden];
    int stride = (int)inputToHidden.count;
    for (int i=0; i<hlCount-1; i++)
    {
        Matrix *hiddenToHidden = [Matrix matrixFromArray:biasPointer+stride
                                                        Rows:hlSize
                                                     Columns:1
                                                        Mode:YCMWeak]; // Hx1
        [result addObject:hiddenToHidden];
        stride += (int)[hiddenToHidden count];
    }
    Matrix *hiddenToOutput = [Matrix matrixFromArray:biasPointer+stride
                                                    Rows:outputSize
                                                 Columns:1
                                                    Mode:YCMWeak]; // Ox1
    [result addObject:hiddenToOutput];
    return result;
}

- (int)weightParameterCount
{
    int hlSize     = self.trainedModel.hiddenLayerSize;
    int hlCount    = self.trainedModel.hiddenLayerCount;
    int inputSize  = self.trainedModel.inputSize;
    int outputSize = self.trainedModel.outputSize;
    return MAX(0, hlCount - 1) * (hlSize * hlSize) +
    inputSize * hlSize + outputSize * hlSize;
}

- (int)biasParameterCount
{
    int hlSize     = self.trainedModel.hiddenLayerSize;
    int hlCount    = self.trainedModel.hiddenLayerCount;
    int outputSize = self.trainedModel.outputSize;
    return MAX(0, hlCount - 1) * hlSize + hlSize + outputSize;
}

- (void)storeWeights:(NSArray *)weights biases:(NSArray *)biases toVector:(Matrix *)vector
{
    // Some really low-level shit going on here. Need to amend.
    double* parameterArray = vector->matrix;
    
    int stride = 0;
    for (Matrix *weightMatrix in weights)
    {
        NSUInteger count = [weightMatrix count];
        memcpy(&parameterArray[stride], weightMatrix->matrix, count * sizeof(double));
        stride += count;
    }
    for (Matrix *biasMatrix in biases)
    {
        NSUInteger count = [biasMatrix count];
        memcpy(&parameterArray[stride], biasMatrix->matrix, count * sizeof(double));
        stride += count;
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

@end
