//
//  NSArray+Matrix.m
//
// YCMatrix
//
// Copyright (c) 2013 - 2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
// http://yconst.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSArray+Matrix.h"

@implementation NSArray (Matrix)

- (Matrix *)matrixSum
{
    Matrix *result;
    for (Matrix *m in self)
    {
        NSAssert([m isKindOfClass:[Matrix class]], @"Array element is not a matrix");
        if (!result)
        {
            result = [m copy];
        }
        else
        {
            [result add:m];
        }
    }
    return result;
}

- (Matrix *)matrixMean
{
    Matrix *result = [self matrixSum];
    [result multiplyWithScalar:1.0 / (double)self.count];
    return result;
}

- (Matrix *)matrixProduct
{
    Matrix *result;
    for (Matrix *m in self)
    {
        NSAssert([m isKindOfClass:[Matrix class]], @"Array element is not a matrix");
        if (!result)
        {
            result = [m copy];
        }
        else
        {
            [result elementWiseMultiply:m];
        }
    }
    return result;
}

- (Matrix *)matrixMax
{
    Matrix *result;
    for (Matrix *m in self)
    {
        NSAssert([m isKindOfClass:[Matrix class]], @"Array element is not a matrix");
        if (!result)
        {
            result = [m copy];
        }
        else
        {
            for (int i=0, n=(int)result.count; i<n; i++)
            {
                double maxValue = -DBL_MAX;
                for (Matrix *m in self)
                {
                    maxValue = MAX(maxValue, [m i:i j:0]);
                }
                [result i:i j:0 set:maxValue];
            }
        }
    }
    return result;
}

- (Matrix *)matrixMin
{
    Matrix *result;
    for (Matrix *m in self)
    {
        NSAssert([m isKindOfClass:[Matrix class]], @"Array element is not a matrix");
        if (!result)
        {
            result = [m copy];
        }
        else
        {
            for (int i=0, n=(int)result.count; i<n; i++)
            {
                double minValue = DBL_MAX;
                for (Matrix *m in self)
                {
                    minValue = MIN(minValue, [m i:i j:0]);
                }
                [result i:i j:0 set:minValue];
            }
        }
    }
    return result;
}

@end
