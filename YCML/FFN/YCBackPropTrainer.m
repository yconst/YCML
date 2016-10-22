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
#import "YCFullyConnectedLayer.h"
#import "YCSigmoidLayer.h"
#import "YCLinearLayer.h"

// N: Size of input
// S: Number of samples
// O: Size of output

@interface YCBackPropTrainer () <YCOptimizerDelegate>

@end

@implementation YCBackPropTrainer
{
    YCOptimizer *_currentOptimizer;
}

+ (Class)problemClass
{
    return [YCBackPropProblem class];
}

+ (Class)optimizerClass
{
    return [YCGradientDescent class];
}

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
        self.settings[@"L1"]                 = @0;
        self.settings[@"L2"]                 = @0.0000;
        self.settings[@"Iterations"]         = @500;
        self.settings[@"Alpha"]              = @0.1;
        self.settings[@"Target"]             = @-1;
        self.settings[@"Samples"]            = @-1;
        self.settings[@"Batch Size"]         = @500;
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
    Matrix *inputTransform  = [input rowWiseMapToDomain:domain basis:StDev];
    Matrix *outputTransform = [output rowWiseMapToDomain:domain basis:MinMax];
    Matrix *invOutTransform = [output rowWiseInverseMapFromDomain:domain basis:MinMax];
    Matrix *scaledInput     = [input matrixByRowWiseMapUsing:inputTransform];
    Matrix *scaledOutput    = [output matrixByRowWiseMapUsing:outputTransform];
    
    // Step II. Populating network with properly sized layers if required
    int hiddenCount      = [self.settings[@"Hidden Layer Count"] intValue];
    int hiddenSize       = [self.settings[@"Hidden Layer Size"] intValue];
    int inputSize             = scaledInput.rows;
    int outputSize            = scaledOutput.rows;

    if (!model || model.layers.count == 0)
    {
        [self initialize:model
           withInputSize:inputSize
              hiddenSize:hiddenSize
             hiddenCount:hiddenCount
              outputSize:outputSize
                      L1:[self.settings[@"L1"] doubleValue]
                      L2:[self.settings[@"L2"] doubleValue]];
    }
    
    // Step III. Defining the Backprop problem and GD properties
    YCBackPropProblem *p       = [[[[self class] problemClass] alloc] initWithInputMatrix:scaledInput
                                                                             outputMatrix:scaledOutput
                                                                                    model:model];
    p.sampleCount              = [self.settings[@"Samples"] intValue];
    p.batchSize                = [self.settings[@"Batch Size"] intValue];
    _currentOptimizer          = [[[[self class] optimizerClass] alloc] initWithProblem:p];
    _currentOptimizer.delegate = self;
    [_currentOptimizer.settings addEntriesFromDictionary:self.settings];
    if ([self.settings[@"Target"] doubleValue] <= 0)
    {
        [_currentOptimizer.settings removeObjectForKey:@"Target"];
    }
    
    // Step IV. Optimizing
    [_currentOptimizer run];
    
    // Step V. Copying statistics, weight and bias matrices.
    model.statistics[@"Iterations"] = _currentOptimizer.state[@"currentIteration"];
    
    NSArray *weights          = [p modelWeightsWithParameters:_currentOptimizer.state[@"values"]];
    NSArray *biases           = [p modelBiasesWithParameters:_currentOptimizer.state[@"values"]];
    [model.layers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        YCFullyConnectedLayer *layer = obj;
        layer.weightMatrix = [weights[idx] copy];
        layer.biasVector = [biases[idx] copy];
    }];
    
    _currentOptimizer = nil;
    
    // Step VI. Copy transform matrices to model
    // TRANSFORM MATRICES SHOULD BE COPIED AFTER TRAINING OTHERWISE
    // THE MODEL WILL SCALE OUTPUTS AND RETURN FALSE ERRORS
    model.inputTransform      = inputTransform;
    model.outputTransform     = invOutTransform;
}

- (void)initialize:(YCFFN *)model
     withInputSize:(int)inputSize
        hiddenSize:(int)hiddenSize
       hiddenCount:(int)hiddenCount
        outputSize:(int)outputSize
                L1:(double)L1
                L2:(double)L2
{
    NSMutableArray *layerSizes = [NSMutableArray array];
    [layerSizes addObject:@(inputSize)];
    for (int i=0; i<hiddenCount; i++)
    {
        [layerSizes addObject:@(hiddenSize)];
    }
    [layerSizes addObject:@(outputSize)];
    
    NSMutableArray *layers = [NSMutableArray array];
    
    [layerSizes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) return;
        YCFullyConnectedLayer *layer;
        if (idx < layerSizes.count - 1)
        {
            layer = [[YCSigmoidLayer alloc] initWithInputSize: [layerSizes[idx - 1] doubleValue]
                                                   outputSize: [layerSizes[idx] doubleValue]];
        }
        else
        {
            layer = [[YCLinearLayer alloc] initWithInputSize: [layerSizes[idx - 1] doubleValue]
                                                  outputSize: [layerSizes[idx] doubleValue]];
        }
        //layer.L1 = L1;
        layer.L2 = L2;
        [layers addObject:layer];
    }];
    model.layers = layers;
}

- (void)stepComplete:(NSDictionary *)info
{
    NSDictionary *uInfo = @{@"Status" : @"Optimizing Weights",
                            @"Hidden Units" : self.settings[@"Hidden Layer Size"],
                            @"Iteration" : info[@"currentIteration"]};
    if (self.delegate && [self.delegate respondsToSelector:@selector(stepComplete:)])
    {
        [self.delegate stepComplete:uInfo];
    }
}

- (void)stop
{
    [super stop];
    if (_currentOptimizer)
    {
        [_currentOptimizer stop];
    }
}

@end
