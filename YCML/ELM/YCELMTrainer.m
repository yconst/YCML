//
//  ELMTrainer.m
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

#import "YCELMTrainer.h"
#import "YCFFN.h"
#import "YCMatrix/YCMatrix.h"
#import "YCMatrix/YCMatrix+Manipulate.h"
#import "YCMatrix/YCMatrix+Advanced.h"
#import "YCMatrix/YCMatrix+Map.h"

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
        self.settings[@"Hidden Layer Size"] = @700;
    }
    return self;
}

- (void)performTrainingModel:(YCFFN *)model
                 inputMatrix:(YCMatrix *)input
                outputMatrix:(YCMatrix *)output
{
    // Input: One sample per column
    // Output: One sample per column
    // Input: NxS, output: OxS
    
    // Step I. Scaling inputs & outputs; determining inverse output scaling matrix
    YCDomain domain           = YCMakeDomain(0, 1);
    YCDomain hiddenDomain     = YCMakeDomain(-1, 2);
    int inputSize             = input.rows;
    int hiddenSize            = [self.settings[@"Hidden Layer Size"] intValue];
    YCMatrix *inputTransform  = [input rowWiseMapToDomain:domain basis:MinMax];
    YCMatrix *outputTransform = [output rowWiseMapToDomain:domain basis:MinMax];
    YCMatrix *invOutTransform = [output rowWiseInverseMapFromDomain:domain basis:MinMax];
    YCMatrix *scaledInput     = [input matrixByRowWiseMapUsing:inputTransform];
    YCMatrix *scaledOutput    = [output matrixByRowWiseMapUsing:outputTransform];

    YCMatrix *hiddenWeights = [YCMatrix randomValuesMatrixOfRows:inputSize
                                                        columns:hiddenSize
                                                         domain:hiddenDomain];
    
    YCMatrix *hiddenBiases = [YCMatrix randomValuesMatrixOfRows:hiddenSize
                                                      columns:1
                                                       domain:hiddenDomain];
    
    YCMatrix *H = [hiddenWeights matrixByTransposingAndMultiplyingWithRight:scaledInput]; // (NxH)T * NxS = HxS
    [H addColumn:hiddenBiases];
    [H applyFunction:model.function];
    
    H = [H appendRow:[YCMatrix matrixOfRows:1 Columns:H.columns Value:1]];
    
    YCMatrix *HI = [H pseudoInverse];
    
    YCMatrix *outputWnB = [scaledOutput matrixByMultiplyingWithRight:HI];
    
    YCMatrix *outputWeights = [[outputWnB matrixWithColumnsInRange:NSMakeRange(0, outputWnB.columns-1)] matrixByTransposing];
    
    YCMatrix *outputBiases = [outputWnB getColumn:outputWnB.columns - 1];
    
    model.weightMatrices = @[hiddenWeights, outputWeights];
    model.biasVectors = @[hiddenBiases, outputBiases];
    
    // Step VI. Copy transform matrices to model
    // TRANSFORM MATRICES SHOULD BE COPIED AFTER TRAINING OTHERWISE
    // THE MODEL WILL SCALE OUTPUTS AND RETURN FALSE ERRORS
    model.inputTransform      = inputTransform;
    model.outputTransform     = invOutTransform;
    
    model.linearOutputs = YES;
}

@end
