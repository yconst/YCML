//
//  ELMTrainer.m
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

// References:
// G.-B. Huang, H. Zhou, X. Ding, and R. Zhang, "Extreme Learning Machine for Regression and
// Multiclass Classification", IEEE Transactions on Systems, Man, and Cybernetics - Part B:
// Cybernetics,  vol. 42, no. 2, pp. 513-529, 2012.

#import "YCELMTrainer.h"
#import "YCFFN.h"
#import "YCTanhLayer.h"
#import "YCLinearLayer.h"
@import YCMatrix;

@implementation YCELMTrainer

+ (Class)modelClass
{
    return [YCFFN class];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.settings[@"Hidden Layer Size"] = @800;
        self.settings[@"C"]                 = @1;
    }
    return self;
}

- (void)performTrainingModel:(YCFFN *)model
                 inputMatrix:(Matrix *)input
                outputMatrix:(Matrix *)output
{
    // Input: One sample per column
    // Output: One sample per column
    // Input: NxS, output: OxS
    
    YCDomain domain           = YCMakeDomain(-1, 2);
    YCDomain hiddenDomain     = YCMakeDomain(-1, 2);
    int inputSize             = input.rows;
    int outputSize            = output.rows;
    int hiddenSize            = [self.settings[@"Hidden Layer Size"] intValue];
    double C                  = [self.settings[@"C"] doubleValue];
    Matrix *inputTransform  = [input rowWiseMapToDomain:domain basis:StDev];
    
    // Step I. Scaling inputs & outputs; determining inverse output scaling matrix
    Matrix *outputTransform = [output rowWiseMapToDomain:domain basis:MinMax];
    Matrix *invOutTransform = [output rowWiseInverseMapFromDomain:domain basis:MinMax];
    Matrix *scaledInput     = [input matrixByRowWiseMapUsing:inputTransform];
    Matrix *scaledOutput    = [output matrixByRowWiseMapUsing:outputTransform];
    
    // Step II. Randomized input weights and biases and calculation of hidden layer output
    YCTanhLayer *hiddenLayer = [[YCTanhLayer alloc] initWithInputSize:inputSize
                                                           outputSize:hiddenSize];
    hiddenLayer.weightMatrix = [Matrix uniformRandomRows:inputSize
                                                 columns:hiddenSize
                                                  domain:hiddenDomain];
    
    hiddenLayer.biasVector = [Matrix uniformRandomRows:hiddenSize
                                               columns:1
                                                domain:hiddenDomain];
    
    Matrix *H = [hiddenLayer forward:scaledInput];
    
    // Step III. Calculating output weights
    // outW = ( eye(nHiddenNeurons)/C + H * H') \ H * targets';
    Matrix *oneOverC      = [Matrix identityOfRows:hiddenSize columns:hiddenSize];
    [oneOverC multiplyWithScalar:1.0/C];
    [oneOverC add:[H matrixByTransposingAndMultiplyingWithLeft:H]];
    Matrix *invA          = [oneOverC pseudoInverse];
    
    Matrix *HTargetsT     = [scaledOutput matrixByTransposingAndMultiplyingWithLeft:H];
    Matrix *outputWeights = [invA matrixByMultiplyingWithRight:HTargetsT];
    
    Matrix *outputBiases  = [Matrix matrixOfRows:outputSize columns:1];
    
    YCLinearLayer *outputLayer = [[YCLinearLayer alloc] initWithInputSize:hiddenSize
                                                               outputSize:outputSize];
    outputLayer.weightMatrix = outputWeights;
    outputLayer.biasVector = outputBiases;
    
    model.layers = @[hiddenLayer, outputLayer];
    
    // Step IV. Copy transform matrices to model
    // TRANSFORM MATRICES SHOULD BE COPIED AFTER TRAINING OTHERWISE
    // THE MODEL WILL SCALE OUTPUTS AND RETURN FALSE ERRORS
    model.inputTransform      = inputTransform;
    model.outputTransform     = invOutTransform;
}

@end
