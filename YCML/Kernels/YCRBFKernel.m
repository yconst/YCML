//
//  YCRBFKernel.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 27/1/16.
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

#import "YCRBFKernel.h"
@import YCMatrix;

// N: Size of input
// P1: Number of samples 1
// P2: Number of samples 2

@implementation YCRBFKernel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.properties[@"Beta"] = @1.0;
    }
    return self;
}

- (Matrix *)kernelValueForA:(Matrix *)a b:(Matrix *)b
{
    // a: NxP1, b: NxP2 -> out: P1xP2
    double beta2 = pow([self.properties[@"Beta"] doubleValue], 2);
    
    int N = a.rows;
    int P1 = a.columns;
    int P2 = b.columns;
    
    // Generate design matrix of dimensions SxD
    Matrix *designmatrix = [Matrix matrixOfRows:P1 columns:P2]; // -> SxD
    
    // Fill up the design matrix, traversing first row and then column
    for (int i=0; i<P1; i++)
    {
        for (int j=0; j<P2; j++)
        {
           double sqsum = 0;
           double val;
           for (int k=0; k<N; k++)
           {
               val = a->matrix[k*P1 + i] - b->matrix[k*P2 + j];
               sqsum += val*val;
           }
           double bfvalue = exp( - sqsum / beta2 );
           designmatrix->matrix[i*P2 + j] = bfvalue;
        }
    }
    return designmatrix;
}

@end
