//
//  YCRBFNet.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 22/4/15.
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

#import "YCRBFNet.h"
@import YCMatrix;

@implementation YCRBFNet

- (Matrix *)activateWithMatrix:(Matrix *)matrix
{
    NSAssert([self.weights count], @"Model not trained");
    NSAssert(matrix.rows == self.centers.rows, @"Input size mismatch");
    
    // 1. Scale input
    Matrix *ScaledInput = matrix;
    if (self.inputTransform)
    {
        ScaledInput = [matrix matrixByRowWiseMapUsing:self.inputTransform];
    }
    
    // 2. Calculate Basis Function Outputs
    //    ->SxD
    Matrix *H = [self designMatrixWithInput:ScaledInput];
    
    // 3. Augment with bias term!
    H = [H appendColumn:[Matrix matrixOfRows:H->rows Columns:1 Value:1.0]];
    
    // 4. Linearly combine RBF to get the output (SxD * DxO)' -> OxS
    Matrix *Output = [H matrixByMultiplyingWithRight:self.weights AndTransposing:YES];
    
    // 5. Scale output and return
    if (self.outputTransform)
    {
        return [Output matrixByRowWiseMapUsing:self.outputTransform];
    }
    return Output;
}

- (Matrix *)designMatrixWithInput:(Matrix *)input
{
    int N = input->rows;
    int S = input->columns;
    int D = self.centers->columns;
    
    // Generate design matrix of dimensions SxD
    Matrix *designmatrix = [Matrix matrixOfRows:S Columns:D]; // -> SxD
    
    // Fill up the design matrix, traversing first row and then column
    dispatch_apply(S, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i)
       {
           @autoreleasepool {
               for (int j=0; j<D; j++)
               {
                   double sqsum = 0;
                   double val;
                   for (int k=0; k<N; k++)
                   {
                       val = input->matrix[k*S + i] - self->_centers->matrix[k*D + j];
                       sqsum += val*val;
                   }
                   double bfvalue = exp( - sqsum / pow(self->_widths->matrix[j], 2));
                   designmatrix->matrix[i*D + j] = bfvalue;
               }
           }
       });
    return designmatrix;
}

#pragma mark Properties

- (int)inputSize
{
    return self.centers.rows;
}

- (int)outputSize
{
    return self.weights.columns;
}

#pragma mark NSCopying Implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCRBFNet *copy = [super copyWithZone:zone];
    if (copy)
    {
        copy.centers = [self.centers copy];
        copy.widths = [self.widths copy];
        copy.weights = [self.weights copy];
        copy.inputTransform = [self.inputTransform copy];
        copy.outputTransform = [self.outputTransform copy];
    }
    return copy;
}

#pragma mark NSCoding Implementation

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.centers = [aDecoder decodeObjectForKey:@"centers"];
        self.widths = [aDecoder decodeObjectForKey:@"widths"];
        self.weights = [aDecoder decodeObjectForKey:@"weights"];
        self.inputTransform = [aDecoder decodeObjectForKey:@"inputTransform"];
        self.outputTransform = [aDecoder decodeObjectForKey:@"outputTransform"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.centers forKey:@"centers"];
    [aCoder encodeObject:self.widths forKey:@"widths"];
    [aCoder encodeObject:self.weights forKey:@"weights"];
    [aCoder encodeObject:self.inputTransform forKey:@"inputTransform"];
    [aCoder encodeObject:self.outputTransform forKey:@"outputTransform"];
}

#pragma mark Text Description

- (NSString *)textDescription
{
    NSMutableString *description = (NSMutableString *)[super textDescription];
    
    // Print RBF function type
    [description appendFormat:@"\nRBF Function is Gaussian\n"];
    
    // Print input and output transform matrices
    if (self.inputTransform)
    {
        [description appendFormat:@"\nInput Transform (%d x %d)\n%@",self.inputTransform.rows,
         self.inputTransform.columns, self.inputTransform];
    }
    if (self.outputTransform)
    {
        [description appendFormat:@"\nOutput Transform (%d x %d)\n%@",self.outputTransform.rows,
         self.outputTransform.columns, self.outputTransform];
    }
    
    // Print centers
    [description appendFormat:@"\nCenters (%d x %d)\n%@",self.centers.rows,
        self.centers.columns, self.centers];
    
    // Print bandwidths
    [description appendFormat:@"\nBandwidths (%d x %d)\n%@",self.widths.rows,
     self.widths.columns, self.widths];
    
    // Print output weights
    [description appendFormat:@"\nOutput Weights (%d x %d)\n%@",self.weights.rows,
     self.weights.columns, self.weights];
    
    return description;
}

@end
