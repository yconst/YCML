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
    
    // 2. Calculate outputs
    Matrix *output = [self.theta matrixByMultiplyingWithRight:scaledInput];
    
    // 5. Scale output and return
    if (self.outputTransform)
    {
        return [output matrixByRowWiseMapUsing:self.outputTransform];
    }
    return output;
}

- (int)inputSize
{
    return self.theta.columns;
}

- (int)outputSize
{
    return self.theta.rows;
}

@end
