//
//  YCRegressionMetrics.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 2/3/15.
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

// References:
// http://scikit-learn.org/stable/modules/model_evaluation.html#regression-metrics
// http://stackoverflow.com/questions/9739460/weird-error-nsassert

#import "YCRegressionMetrics.h"
@import YCMatrix;
#import "YCDataframe.h"
#import "YCDataframe+Matrix.h"

Matrix *conditionalConvertToMatrix(id object);

// TODO:
// These methods say they accept dataframes, but they can also be
// provided with matrices. In fact, this is what the -conditionalConvertToMatrix
// method is doing. This should be better implemented and clearly explained.

double MSE(id trueData, id predictedData)
{
    Matrix *trueMatrix = conditionalConvertToMatrix(trueData);
    Matrix *predictedMatrix = conditionalConvertToMatrix(predictedData);
    Matrix *sv = [trueMatrix matrixBySubtracting:predictedMatrix];
    [sv elementWiseMultiply:sv];
    Matrix *means = [sv meansOfRows];
    return [means meansOfColumns]->matrix[0];
}


double RSquared(id trueData, id predictedData)
{
    // Calculates 1 - RSS/TSS
    
    Matrix *trueMatrix = conditionalConvertToMatrix(trueData);
    Matrix *predictedMatrix = conditionalConvertToMatrix(predictedData);
    
    Matrix *numMatrix = [trueMatrix matrixBySubtracting:predictedMatrix];
    [numMatrix elementWiseMultiply:numMatrix];
    numMatrix = [numMatrix sumsOfRows];
    
    Matrix *denMatrix = [trueMatrix matrixBySubtractingColumn:[trueMatrix meansOfRows]];
    [denMatrix elementWiseMultiply:denMatrix];
    denMatrix = [denMatrix sumsOfRows];
    
    NSUInteger outCount = [numMatrix count];
    
    Matrix *resMatrix = [Matrix matrixLike:numMatrix];
    
    for (int i=0; i<outCount; i++)
    {
        double num = numMatrix->matrix[i];
        double den = denMatrix->matrix[i];
        if (den == 0)
        {
            if (num == 0)
            {
                resMatrix->matrix[i] = 1.0;
            }
            resMatrix->matrix[i] = 0.0;
        }
        resMatrix->matrix[i] = 1.0 - num/den;
    }
    return [resMatrix meansOfColumns]->matrix[0];
}

Matrix *conditionalConvertToMatrix(id object)
{
    if ([object isKindOfClass:[Matrix class]]) return object;
    NSCAssert([object isKindOfClass:[YCDataframe class]], @"Wrong parameter type");
    YCDataframe *df = object;
    NSArray *ca = [df conversionArray];
    return [df getMatrixUsingConversionArray:ca];
}
