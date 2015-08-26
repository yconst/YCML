//
//  YCBinaryRBMProblem.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 30/7/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCBinaryRBMProblem.h"
#import "YCBinaryRBM.h"

@implementation YCBinaryRBMProblem

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
    return (int)self.trainedModel.weights.count;
}

- (Matrix *)parameterBounds
{
    return nil;
}

- (Matrix *)initialValuesRangeHint
{
    int parameterCount = [self parameterCount];
    Matrix *minValues = [Matrix matrixOfRows:parameterCount Columns:1 Value:-0.1];
    Matrix *maxValues = [Matrix matrixOfRows:parameterCount Columns:1 Value:0.1];
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
    
    Matrix *inputSample = [_inputMatrix matrixBySamplingColumns:[self.trainedModel.trainingSettings[@"Samples"] intValue]
                                                    Replacement:NO];
    
    Matrix *positiveHiddenProbs = [self.trainedModel propagateToHidden:inputSample];
    Matrix *positiveHiddenState = [self.trainedModel sampleHiddenGivenVisible:inputSample];
    
    Matrix *negativeVisibleProbs = [self.trainedModel propagateToVisible:positiveHiddenState];
    Matrix *negativeVisibleState = [self.trainedModel sampleVisibleGivenHidden:positiveHiddenState];
    
    Matrix *negativeHiddenProbs = [self.trainedModel propagateToHidden:negativeVisibleState];
    
    Matrix *positiveAssociations = [inputSample matrixByMultiplyingWithRight:positiveHiddenProbs];
    Matrix *negativeAssociations = [negativeVisibleProbs matrixByTransposingAndMultiplyingWithRight:negativeHiddenProbs]; // should be OUTER product
    
    positiveAssociations = [positiveAssociations meansOfRows];
    negativeAssociations = [negativeAssociations meansOfRows];
    
    Matrix *weightUpdates = positiveAssociations;
    [weightUpdates subtract:negativeAssociations];
    
    Matrix *visibleBiasUpdates = [positiveHiddenProbs matrixBySubtracting:negativeHiddenProbs];
    visibleBiasUpdates = [visibleBiasUpdates meansOfRows];
    
    Matrix *hiddenBiasUpdates = [inputSample matrixBySubtracting:negativeVisibleProbs];
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
                                         Rows:self.trainedModel.weights.rows
                                      Columns:self.trainedModel.weights.columns
                                         Mode:YCMWeak];
    return weights;
}

- (Matrix *)visibleBiasWithParameters:(Matrix *)parameters
{
    Matrix *visible = [Matrix matrixFromArray:parameters->matrix + self.trainedModel.weights.count
                                         Rows:self.trainedModel.visibleBiases.rows
                                      Columns:1
                                         Mode:YCMWeak];
    return visible;
}

- (Matrix *)hiddenBiasWithParameters:(Matrix *)parameters
{
    Matrix *hidden = [Matrix matrixFromArray:parameters->matrix + self.trainedModel.weights.count +
                                                self.trainedModel.visibleBiases.count
                                         Rows:self.trainedModel.hiddenBiases.rows
                                      Columns:1
                                         Mode:YCMWeak];
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
