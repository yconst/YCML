//
//  YCLinRegTrainer.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 12/12/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCLinRegTrainer.h"
#import "YCLinRegModel.h"
#import "YCLinearModelProblem.h"

@implementation YCLinRegTrainer

+ (Class)modelClass
{
    return [YCLinRegModel class];
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.settings[@"L2"]                 = @0.001;
        self.settings[@"Iterations"]         = @2000;
        self.settings[@"Alpha"]              = @0.2;
        self.settings[@"Target"]             = @-1;
    }
    return self;
}

- (void)performTrainingModel:(YCLinRegModel *)model
                 inputMatrix:(Matrix *)input
                outputMatrix:(Matrix *)output
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
    
    YCLinearModelProblem *p = [[YCLinearModelProblem alloc] initWithInputMatrix:scaledInput
                                                                   outputMatrix:scaledOutput
                                                                          model:model];
    
    p.l2                              = [self.settings[@"L2"] doubleValue];
    YCGradientDescent *optimizer      = [[YCGradientDescent alloc] initWithProblem:p];
    [optimizer.settings addEntriesFromDictionary:self.settings];
    if ([self.settings[@"Target"] doubleValue] <= 0)
    {
        [optimizer.settings removeObjectForKey:@"Target"];
    }
    
    [optimizer run];
    
    Matrix *theta = [p thetaWithParameters:optimizer.state[@"values"]];
    model.theta = [theta copy];
    
    // Step VI. Copy transform matrices to model
    // TRANSFORM MATRICES SHOULD BE COPIED AFTER TRAINING OTHERWISE
    // THE MODEL WILL SCALE OUTPUTS AND RETURN FALSE ERRORS
    model.inputTransform      = inputTransform;
    model.outputTransform     = invOutTransform;
}

@end
