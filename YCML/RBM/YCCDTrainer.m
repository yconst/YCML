//
//  YCBinaryRBMTrainer.m
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

#import "YCCDTrainer.h"
#import "YCBinaryRBM.h"
#import "YCCDProblem.h"
#import "YCDataframe.h"
#import "YCDataframe+Matrix.h"
#import "YCOptimizer.h"
#import "YCGradientDescent.h"

@interface YCCDTrainer () <YCOptimizerDelegate>

@end

@implementation YCCDTrainer

+ (Class)optimizerClass
{
    return [YCGradientDescent class];
}

+ (Class)modelClass
{
    return [YCBinaryRBM class];
}

-(id)init
{
    if (self = [super init])
    {
        self.settings[@"Hidden Layer Size"]  = @3;
        self.settings[@"Lambda"]             = @0.0001;
        self.settings[@"Iterations"]         = @500;
        self.settings[@"Alpha"]              = @0.1;
        self.settings[@"Samples"]            = @-1;
    }
    return self;
}

- (YCBinaryRBM *)train:(YCBinaryRBM *)model input:(YCDataframe *)input
{
    YCBinaryRBM *theModel = model;
    if (!theModel)
    {
        theModel = [[[[self class] modelClass] alloc] init];
    }
    theModel.properties[@"InputMinValues"]        = [input stat:@"min"];
    theModel.properties[@"InputMaxValues"]        = [input stat:@"max"];
    theModel.properties[@"InputConversionArray"]  = [input conversionArray];
    [theModel.trainingSettings addEntriesFromDictionary:self.settings];
    Matrix *inputM = [input getMatrixUsingConversionArray:theModel.properties[@"InputConversionArray"]];
    [self train:theModel inputMatrix:inputM];
    return theModel;
}

- (YCBinaryRBM *)train:(YCBinaryRBM *)model inputMatrix:(Matrix *)input
{
    self.shouldStop = false;
    YCBinaryRBM *theModel = model;
    if (!theModel)
    {
        theModel = [[[[self class] modelClass] alloc] init];
    }
    [self performTrainingModel:theModel inputMatrix:input];
    return theModel;
}

- (void)performTrainingModel:(YCBinaryRBM *)model inputMatrix:(Matrix *)input
{
    // Input: One sample per column
    // Output: One sample per column
    // Input: NxS, output: OxS
    
    // Step I. Populating network with properly sized matrices
    int hiddenSize       = [self.settings[@"Hidden Layer Size"] intValue];
    int inputSize             = input.rows;
    [self initialize:model withInputSize:inputSize hiddenSize:hiddenSize];
    
    // Step III. Defining the Backprop problem and GD properties
    YCCDProblem *p      = [[YCCDProblem alloc] initWithInputMatrix:input
                                                                           model:model];
    p.lambda                          = [self.settings[@"Lambda"] doubleValue];
    p.sampleCount                     = [self.settings[@"Samples"] intValue];
    YCOptimizer *optimizer      = [[[[self class] optimizerClass] alloc] initWithProblem:p];
    optimizer.delegate                = self;
    [optimizer.settings addEntriesFromDictionary:self.settings];
    
    // Step IV. Optimizing
    [optimizer run];
    
    // Step V. Copying statistics, weight and bias matrices.
    model.statistics[@"Iterations"] = optimizer.state[@"currentIteration"];
    
    Matrix *state = optimizer.state[@"values"];
    
    model.weights = [Matrix matrixFromMatrix:[p weightsWithParameters:state]];
    model.visibleBiases = [Matrix matrixFromMatrix:[p visibleBiasWithParameters:state]];
    model.hiddenBiases = [Matrix matrixFromMatrix:[p hiddenBiasWithParameters:state]];
}

- (void)initialize:(YCBinaryRBM *)model withInputSize:(int)inputSize hiddenSize:(int)hiddenSize
{
    model.weights = [Matrix matrixOfRows:hiddenSize columns:inputSize];
    model.visibleBiases = [Matrix matrixOfRows:inputSize columns:1];
    model.hiddenBiases = [Matrix matrixOfRows:hiddenSize columns:1];
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

@end
