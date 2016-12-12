//
//  YCkNN.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 6/12/16.
//  Copyright © 2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

#import "YCKPM.h"

@implementation YCKPM

- (Matrix *)activateWithMatrix:(Matrix *)matrix
{
    double bias = MAX(1E-12, [self.trainingSettings[@"Bias"] doubleValue]);
    
    // 1. Scale input
    Matrix *scaledInput = matrix;
    if (self.inputTransform)
    {
        scaledInput = [matrix matrixByRowWiseMapUsing:self.inputTransform];
    }
    
    // 2. Prepare output matrix and split input matrix to columns
    //    TODO: Vectorize this!
    Matrix *output = [Matrix matrixOfRows:self.targets.rows columns:scaledInput.columns];
    NSArray *examples = [scaledInput columnsAsNSArray];
    
    // 3. For each example: Find similarity with prototypes; weigh each
    //    prototype's corresponding target and sum them up together
    for (int i=0; i<examples.count; i++)
    {
        Matrix *example = examples[i];
        Matrix *diff = [self.prototypes matrixBySubtractingColumn:example];
        [diff square];
        Matrix *weights = [diff sumsOfColumns];
        [weights applyFunction:^double(double value) {
            return 1.0/(value*value*value + bias); // FIXME: Use YCKernel!!!
        }];
        
        double sum = [weights sum];
        [weights multiplyWithScalar:1/sum];
        
        Matrix *singleOutput = [[self.targets matrixByMultiplyingWithRow:weights] sumsOfRows];
        [output setColumn:i value:singleOutput];
    }
    
    // 4. Reverse-scale output and return
    if (self.outputTransform)
    {
        return [output matrixByRowWiseMapUsing:self.outputTransform];
    }
    return output;
}

@end
