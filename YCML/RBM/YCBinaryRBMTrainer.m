//
//  YCBinaryRBMTrainer.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 30/7/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCBinaryRBMTrainer.h"
#import "YCBinaryRBM.h"
#import "YCBinaryRBMProblem.h"
#import "YCDataframe.h"
#import "YCDataframe+Matrix.h"
#import "YCOptimizer.h"
#import "YCGradientDescent.h"

@implementation YCBinaryRBMTrainer

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
        self.settings[@"Hidden Layer Size"]  = @5;
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
    YCBinaryRBMProblem *p      = [[YCBinaryRBMProblem alloc] initWithInputMatrix:input
                                                                           model:model];
    p.lambda                          = [self.settings[@"Lambda"] doubleValue];
    p.sampleCount                     = [self.settings[@"Samples"] intValue];
    YCOptimizer *optimizer      = [[[[self class] optimizerClass] alloc] initWithProblem:p];
    [optimizer.settings addEntriesFromDictionary:self.settings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(respondToIterationNotification:) name:@"iterationComplete"
                                               object:nil];
    
    // Step IV. Optimizing
    [optimizer run];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Step V. Copying statistics, weight and bias matrices.
    model.statistics[@"Iterations"] = optimizer.state[@"currentIteration"];
    
    Matrix *state = optimizer.state[@"values"];
    
    model.weights = [Matrix matrixFromMatrix:[p weightsWithParameters:state]];
    model.visibleBiases = [Matrix matrixFromMatrix:[p visibleBiasWithParameters:state]];
    model.hiddenBiases = [Matrix matrixFromMatrix:[p hiddenBiasWithParameters:state]];
}

- (void)initialize:(YCBinaryRBM *)model withInputSize:(int)inputSize hiddenSize:(int)hiddenSize
{
    model.weights = [Matrix matrixOfRows:inputSize Columns:hiddenSize];
    model.visibleBiases = [Matrix matrixOfRows:inputSize Columns:1];
    model.hiddenBiases = [Matrix matrixOfRows:hiddenSize Columns:1];
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


@end
