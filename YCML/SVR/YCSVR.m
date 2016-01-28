//
//  YCSVR.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 11/12/15.
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
// V: Support Vector count
// O: Size of output (for SVM-Regression O == 1)

#import "YCSVR.h"
#import "YCModelKernel.h"
@import YCMatrix;

@implementation YCSVR

- (Matrix *)activateWithMatrix:(Matrix *)matrix
{
    NSAssert([self.sv count], @"Model not trained");
    NSAssert([matrix rows] == self.inputSize, @"Input size mismatch");
    
    // 1. Scale input
    Matrix *scaledInput = matrix;
    if (self.inputTransform)
    {
        scaledInput = [matrix matrixByRowWiseMapUsing:self.inputTransform];
    }
    
    // 2. Calculate kernel
    Matrix *k = [self.kernel kernelValueForA:self.sv b:scaledInput]; //(NxV)T * NxS = VxS
    
    // 3. Calculate output (algorithm is single output!)
    Matrix *output = [self.lambda matrixByMultiplyingWithRight:k];
    
    [output incrementAll:self.b];
    
    // 4. Reverse-scale output and return
    if (self.outputTransform)
    {
        return [output matrixByRowWiseMapUsing:self.outputTransform];
    }
    return output;
}

- (int)inputSize
{
    return self.sv.rows;
}

- (int)outputSize
{
    return 1;
}

@end
