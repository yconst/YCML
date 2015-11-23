//
//  YCBinaryRBMProblem.m
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

#import "YCCDProblem.h"
#import "YCBinaryRBM.h"

@implementation YCCDProblem

- (instancetype)initWithInputMatrix:(Matrix *)inputMatrix model:(YCBinaryRBM *)model
{
    self = [super init];
    if (self)
    {
        _inputMatrix = inputMatrix;
        self.trainedModel = model;
    }
    return self;
}

- (int)parameterCount
{
    return (int)self.trainedModel.weights.count + (int)self.trainedModel.visibleBiases.count +
    (int)self.trainedModel.hiddenBiases.count;
}

- (Matrix *)parameterBounds
{
    return nil;
}

- (Matrix *)initialValuesRangeHint
{
    int parameterCount = [self parameterCount];
    Matrix *minValues = [Matrix matrixOfRows:parameterCount columns:1 value:-0.1];
    Matrix *maxValues = [Matrix matrixOfRows:parameterCount columns:1 value:0.1];
    return [minValues appendColumn:maxValues];
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

- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters
{
    self.trainedModel.weights = [self weightsWithParameters:parameters];
    self.trainedModel.visibleBiases = [self visibleBiasWithParameters:parameters];
    self.trainedModel.hiddenBiases = [self hiddenBiasWithParameters:parameters];
    
    Matrix *fe = [self.trainedModel freeEnergy:_inputMatrix];
    [fe elementWiseMultiply:fe];
    double sum = [fe sum];
    [target i:0 j:0 set:sum];
}

- (void)derivatives:(Matrix *)target parameters:(Matrix *)parameters
{
    self.trainedModel.weights = [self weightsWithParameters:parameters];
    self.trainedModel.visibleBiases = [self visibleBiasWithParameters:parameters];
    self.trainedModel.hiddenBiases = [self hiddenBiasWithParameters:parameters];
    
    Matrix *inputSample = self.sampleCount <= 0 ? _inputMatrix :
    [_inputMatrix matrixBySamplingColumns:self.sampleCount
                                        replacement:NO];
    
    Matrix *positiveHiddenProbs = [self.trainedModel propagateToHidden:inputSample];
    Matrix *positiveHiddenState = [self.trainedModel sampleHiddenGivenVisible:inputSample];
    
    Matrix *negativeVisibleProbs = [self.trainedModel propagateToVisible:positiveHiddenState];
    Matrix *negativeVisibleState = [self.trainedModel sampleVisibleGivenHidden:positiveHiddenState];
    
    Matrix *negativeHiddenProbs = [self.trainedModel propagateToHidden:negativeVisibleState];
    
    Matrix *positiveAssociations = [inputSample matrixByTransposingAndMultiplyingWithLeft:positiveHiddenProbs];
    Matrix *negativeAssociations = [negativeVisibleProbs matrixByTransposingAndMultiplyingWithLeft:negativeHiddenProbs]; // should be OUTER product
    
    Matrix *weightUpdates = negativeAssociations;
    [weightUpdates subtract:positiveAssociations];
    
    Matrix *visibleBiasUpdates = [negativeHiddenProbs matrixBySubtracting:positiveHiddenProbs];
    visibleBiasUpdates = [visibleBiasUpdates meansOfRows];
    
    Matrix *hiddenBiasUpdates = [negativeVisibleProbs matrixBySubtracting:inputSample];
    hiddenBiasUpdates = [hiddenBiasUpdates meansOfRows];
    
    [self storeWeights:weightUpdates
         visibleBiases:visibleBiasUpdates
          hiddenBiases:hiddenBiasUpdates
              toVector:target];
}

// Parameter sequence is Weights, Visible biases, Hidden biases

- (Matrix *)weightsWithParameters:(Matrix *)parameters
{
    Matrix *weights = [Matrix matrixFromArray:parameters->matrix
                                         rows:self.trainedModel.weights.rows
                                      columns:self.trainedModel.weights.columns
                                         mode:YCMWeak];
    return weights;
}

- (Matrix *)visibleBiasWithParameters:(Matrix *)parameters
{
    Matrix *visible = [Matrix matrixFromArray:parameters->matrix + self.trainedModel.weights.count
                                         rows:self.trainedModel.visibleBiases.rows
                                      columns:1
                                         mode:YCMWeak];
    return visible;
}

- (Matrix *)hiddenBiasWithParameters:(Matrix *)parameters
{
    Matrix *hidden = [Matrix matrixFromArray:parameters->matrix + self.trainedModel.weights.count +
                                                self.trainedModel.visibleBiases.count
                                         rows:self.trainedModel.hiddenBiases.rows
                                      columns:1
                                         mode:YCMWeak];
    return hidden;
}

- (void)storeWeights:(Matrix *)weights
       visibleBiases:(Matrix *)vBiases
        hiddenBiases:(Matrix *)hBiases
            toVector:(Matrix *)vector
{
    NSAssert(vector.count == weights.count + vBiases.count + hBiases.count, @"Vector size mismatch");
    memcpy(vector->matrix, weights->matrix, weights.count * sizeof(double));
    memcpy(vector->matrix + weights.count, vBiases->matrix, vBiases.count * sizeof(double));
    memcpy(vector->matrix + weights.count + vBiases.count, hBiases->matrix, hBiases.count * sizeof(double));
}

@end
