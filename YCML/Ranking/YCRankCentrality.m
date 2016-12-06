//
//  YCRankCentrality.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 24/11/16.
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

#import "YCRankCentrality.h"
@import YCMatrix;

@implementation YCRankCentrality

+ (Matrix *)transitionMatrixWithComparisons:(Matrix *)comparisons
{
    NSAssert(comparisons.rows == comparisons.columns && comparisons.rows >= 2,
             @"Incorrect Matrix size");
    
    Matrix *comparisonsCopy = [comparisons copy];
    // Normalize losses counts to fractions for each pair
    for (int i=0, k=comparisonsCopy.columns; i<k; i++)
    {
        for (int j=i+1; j<k; j++)
        {
            double a = [comparisonsCopy i:i j:j];
            double b = [comparisonsCopy i:j j:i];
            double sum = a+b;
            if (sum == 0) continue;
            double newA = a / sum;
            double newB = b / sum;
            [comparisonsCopy i:i j:j set:newA];
            [comparisonsCopy i:j j:i set:newB];
        }
    }
    
    // Normalize rows of comparisons matrix (ie graph nodes) to derive
    // the transition matrix
    Matrix *transitions = comparisonsCopy;
    [transitions setDiagonalTo:0];
    
    double max = [[transitions sumsOfRows] max];
    [transitions multiplyWithScalar:1/max];
    
    Matrix *sums = [transitions sumsOfRows];
    for (int i=0, j=transitions.rows; i<j; i++)
    {
        [transitions i:i j:i set:1 - [sums i:i j:0]];
    }
    
    return transitions;
}

+ (Matrix *)scoresWithTransitionMatrix:(Matrix *)transitionMatrix
{
    // Acquire top left eigenvector and return
    // Note that eigenvectors are returned on per row, so we need to transpose
    NSDictionary *eigenDictionary = [transitionMatrix eigenvectorsAndEigenvalues];
    Matrix *values = eigenDictionary[@"Real Eigenvalues"];
    
    // Eigenvalue is not exactly 1.0 so we need to make a comparison
    double minDiff = DBL_MAX;
    int vectorIndex = -1;
    for (int i=0, k=(int)values.count; i<k; i++)
    {
        double diff = ABS([values i:0 j:i] - 1.0);
        if (diff < 1E-5 && diff < minDiff)
        {
            vectorIndex = i;
            minDiff = diff;
        }
    }
    
    // Return vector if found, nil otherwise
    if (vectorIndex != -1)
    {
        Matrix *ret = [eigenDictionary[@"Left Eigenvectors"] column:vectorIndex];
        [ret absolute];
        return ret;
    }
    return nil;
}

+ (Matrix *)scoresWithComparisons:(Matrix *)comparisons
{
    NSAssert(comparisons.rows == comparisons.columns && comparisons.rows >= 2,
             @"Incorrect Matrix size");
    
    Matrix *transitions = [self transitionMatrixWithComparisons:comparisons];
    return [self scoresWithTransitionMatrix:transitions];
}

@end
