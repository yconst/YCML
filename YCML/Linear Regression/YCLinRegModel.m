//
//  YCLinRegModel.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 12/12/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCLinRegModel.h"

@implementation YCLinRegModel

- (Matrix *)activateWithMatrix:(Matrix *)matrix
{
    NSAssert(self.theta, @"Model not trained");
    NSAssert([matrix rows] == self.inputSize, @"Input size mismatch");
    
    // 1. Scale input
    Matrix *scaledInput = matrix; // NxS
    if (self.inputTransform)
    {
        scaledInput = [matrix matrixByRowWiseMapUsing:self.inputTransform];
    }
    
    // 2. Augment with bias term and multiply with weights
    // O = W * N
    int M = scaledInput->columns;
    // TODO: Optimize this to not add a whole row to the
    // input!
    Matrix *inputWithBias = [scaledInput appendRow:[Matrix matrixOfRows:1 columns:M value:1]];
    Matrix *output = [self.theta matrixByTransposingAndMultiplyingWithRight:inputWithBias];
    
    // 5. Scale output and return
    if (self.outputTransform)
    {
        return [output matrixByRowWiseMapUsing:self.outputTransform];
    }
    return output;
}

- (int)inputSize
{
    return self.theta.rows - 1;
}

- (int)outputSize
{
    return self.theta.columns;
}

@end
