//
//  YCBackPropTrainer.m
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
#import "YCBackPropTrainer.h"
#import "YCBackPropProblem.h"
#import "YCFFN.h"
#import "YCGradientDescent.h"

// N: Size of input
// S: Number of samples
// O: Size of output

@implementation YCBackPropTrainer

+ (Class)modelClass
{
    return [YCFFN class];
}

-(id)init
{
    if (self = [super init])
    {
        self.settings[@"Hidden Layer Count"] = @1;
        self.settings[@"Hidden Layer Size"]  = @5;
        self.settings[@"Lambda"]             = @0.0001;
        self.settings[@"Iterations"]         = @500;
        self.settings[@"Alpha"]              = @0.1;
        self.settings[@"Target"]             = @-1;
    }
    return self;
}

- (void)performTrainingModel:(YCFFN *)model inputMatrix:(Matrix *)input outputMatrix:(Matrix *)output
{
    // Input: One sample per column
    // Output: One sample per column
    // Input: NxS, output: OxS
    
    // Step I. Scaling inputs & outputs; determining inverse output scaling matrix
    YCDomain domain = YCMakeDomain(0, 1);
    Matrix *inputTransform  = [input rowWiseMapToDomain:domain basis:MinMax];
    Matrix *outputTransform = [output rowWiseMapToDomain:domain basis:MinMax];
    Matrix *invOutTransform = [output rowWiseInverseMapFromDomain:domain basis:MinMax];
    Matrix *scaledInput     = [input matrixByRowWiseMapUsing:inputTransform];
    Matrix *scaledOutput    = [output matrixByRowWiseMapUsing:outputTransform];
    
    // Step II. Populating network with properly sized matrices
    int hiddenCount      = [self.settings[@"Hidden Layer Count"] intValue];
    int hiddenSize       = [self.settings[@"Hidden Layer Size"] intValue];
    int inputSize             = scaledInput.rows;
    int outputSize            = scaledOutput.rows;
    [self initialize:model withInputSize:inputSize hiddenSize:hiddenSize hiddenCount:hiddenCount outputSize:outputSize];
    
    // Step III. Defining the Backprop problem and GD properties
    YCBackPropProblem *p      = [[[self problemClass] alloc] initWithInputMatrix:scaledInput
                                                                    outputMatrix:scaledOutput
                                                                           model:model];
    p.lambda                          = [self.settings[@"Lambda"] doubleValue];
    YCOptimizer *optimizer      = [[[self optimizerClass] alloc] initWithProblem:p];
    [optimizer.settings addEntriesFromDictionary:self.settings];
    if ([self.settings[@"Target"] doubleValue] <= 0)
    {
        [optimizer.settings removeObjectForKey:@"Target"];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(respondToIterationNotification:) name:@"iterationComplete"
                                               object:nil];
    
    // Step IV. Optimizing
    [optimizer run];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Step V. Copying statistics, weight and bias matrices.
    model.statistics[@"Iterations"] = optimizer.state[@"currentIteration"];
    
    NSArray *weights          = [p modelWeightsWithParameters:optimizer.state[@"values"]];
    model.weightMatrices      = [[NSArray alloc] initWithArray:weights copyItems:YES];
    NSArray *biases           = [p modelBiasesWithParameters:optimizer.state[@"values"]];
    model.biasVectors         = [[NSArray alloc] initWithArray:biases copyItems:YES];
    
    // Step VI. Copy transform matrices to model
    // TRANSFORM MATRICES SHOULD BE COPIED AFTER TRAINING OTHERWISE
    // THE MODEL WILL SCALE OUTPUTS AND RETURN FALSE ERRORS
    model.InputTransform      = inputTransform;
    model.OutputTransform     = invOutTransform;
}

- (void)initialize:(YCFFN *)model
     withInputSize:(int)inputSize
        hiddenSize:(int)hiddenSize
       hiddenCount:(int)hiddenCount
        outputSize:(int)outputSize
{
    if (hiddenCount == 0)
    {
        NSMutableArray *weightMatrices = [NSMutableArray array];
        NSMutableArray *biasVectors = [NSMutableArray array];
        [weightMatrices addObject:[Matrix matrixOfRows:inputSize Columns:outputSize]]; // NxO
        [biasVectors addObject:[Matrix matrixOfRows:outputSize Columns:1]]; // Ox1
        model.weightMatrices = weightMatrices;
        model.biasVectors = biasVectors;
    }
    else
    {
        NSMutableArray *weightMatrices = [NSMutableArray array];
        NSMutableArray *biasVectors = [NSMutableArray array];
        [weightMatrices addObject:[Matrix matrixOfRows:inputSize Columns:hiddenSize]]; // NxH
        [biasVectors addObject:[Matrix matrixOfRows:hiddenSize Columns:1]]; // Hx1
        for (int i=0; i<hiddenCount-1; i++)
        {
            [weightMatrices addObject:[Matrix matrixOfRows:hiddenSize Columns:hiddenSize]]; // HxH
            [biasVectors addObject:[Matrix matrixOfRows:hiddenSize Columns:1]]; // Hx1
        }
        [weightMatrices addObject:[Matrix matrixOfRows:hiddenSize Columns:outputSize]]; // HxO
        [biasVectors addObject:[Matrix matrixOfRows:outputSize Columns:1]]; // Ox1
        model.weightMatrices = weightMatrices;
        model.biasVectors = biasVectors;
    }
}

- (void)respondToIterationNotification:(NSNotification *)notification
{
    NSDictionary *state = notification.userInfo;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TrainingStep"
                                                        object:self
                                                      userInfo:@{@"Status" : @"Optimizing Weights",
                                                                 @"Hidden Units" : self.settings[@"Hidden Layer Size"],
                                                                 @"Iteration" : state[@"currentIteration"]}];
}

- (Class)problemClass
{
    return [YCBackPropProblem class];
}

- (Class)optimizerClass
{
    return [YCGradientDescent class];
}

@end
