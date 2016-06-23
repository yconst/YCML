//
//  YCHypervolumeMetric.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 18/1/16.
//  Copyright (c) 2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

#import "YCHypervolumeMetric.h"
#import "YCHypE.h"
@import YCMatrix;

@implementation YCHypervolumeMetric

- (double)estimateHypervolumeForObjectiveFunctionVectors:(NSArray *)vectors
                                                 targets:(Matrix *)targets
                                              sampleSize:(int)sampleSize
                                                   lowerReference:(Matrix *)lowerReference
                                                   upperReference:(Matrix *)upperReference
{
    Matrix *lower = lowerReference ? lowerReference : [vectors matrixMin];
    Matrix *upper = upperReference ? upperReference : [vectors matrixMax];
    
    int dominatedSamples = 0;
    
    for (int i=0; i<sampleSize; i++)
    {
        Matrix *sample = [Matrix uniformRandomLowerBound:lower upperBound:upper];
        
        for (Matrix *m in vectors)
        {
            if ([YCHypE vector:m weaklyDominates:sample targets:targets])
            {
                dominatedSamples++;
                break;
            }
        }
    }
    
    return [[upper matrixBySubtracting:lower] product] * ((double)dominatedSamples / (double)sampleSize);
}

@end
