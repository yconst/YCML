//
//  Matrix+Map.m
//
// YCMatrix
//
// Copyright (c) 2013 - 2015 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

#import "Matrix+Map.h"
#import "Matrix+Manipulate.h"

@implementation Matrix (Map)

- (Matrix *)matrixByRowWiseMapUsing:(Matrix *)transform
{
    double *mtxArray = self->matrix;
    double *transformArray = transform->matrix;
    Matrix *transformed = [Matrix matrixOfRows:rows Columns:columns];
    double *transformedArray = transformed->matrix;
    dispatch_apply(rows, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i)
                   {
                       double a = transformArray[2*i];
                       double b = transformArray[2*i + 1];
                       for (int j=0; j<columns; j++)
                       {
                           transformedArray[i*columns + j] = mtxArray[i*columns + j] * a + b;
                       }
                   });
    return transformed;
}

- (Matrix *)rowWiseMapToDomain:(YCDomain)domain basis:(MapBasis)basis
{
    int numRows = self->rows;
    int numColumns = self->columns;
    NSArray *matrixRows = [self rowsAsNSArray];
    Matrix *transform = [Matrix matrixOfRows:numRows Columns:2];
    int i=0;
    double tmean = domain.location + domain.length * 0.5;
    double trange = domain.length;
    for (Matrix *m in matrixRows)
    {
        double a, b;
        double fmean = 0, frange = 0;
        for (int j=0; j<numColumns; j++)
        {
            fmean += m->matrix[j];
        }
        fmean /= numColumns;
        if (basis == StDev)
        {
            double fstdev = 0;
            for (int j=0; j<numColumns; j++)
            {
                fstdev += pow(m->matrix[j] - fmean, 2);
            }
            fstdev = sqrt(fstdev/numColumns);
            frange = 2*fstdev;
        }
        else
        {
            double min = DBL_MAX;
            double max = DBL_MIN;
            for (int j=0; j<numColumns; j++)
            {
                min = MIN(min, m->matrix[j]);
                max = MAX(max, m->matrix[j]);
            }
            frange = max - min;
        }
        a = trange / frange;
        b = tmean - fmean * (trange / frange);
        [transform setValue:a Row:i Column:0];
        [transform setValue:b Row:i++ Column:1];
    }
    return transform;
}

- (Matrix *)rowWiseInverseMapFromDomain:(YCDomain)domain basis:(MapBasis)basis
{
    int numRows = self->rows;
    int numColumns = self->columns;
    NSArray *matrixRows = [self rowsAsNSArray];
    Matrix *transform = [Matrix matrixOfRows:numRows Columns:2];
    int i=0;
    double fmean = domain.location + domain.length * 0.5;
    double frange = domain.length;
    for (Matrix *m in matrixRows)
    {
        double a, b;
        double tmean = 0, trange = 0;
        for (int j=0; j<numColumns; j++)
        {
            tmean += m->matrix[j];
        }
        tmean /= numColumns;
        if (basis == StDev)
        {
            double tstdev = 0;
            for (int j=0; j<numColumns; j++)
            {
                tstdev += pow(m->matrix[j] - tmean, 2);
            }
            tstdev = sqrt(tstdev/numColumns);
            trange = 2*tstdev;
        }
        else
        {
            double min = DBL_MAX;
            double max = DBL_MIN;
            for (int j=0; j<numColumns; j++)
            {
                min = MIN(min, m->matrix[j]);
                max = MAX(max, m->matrix[j]);
            }
            trange = max - min;
        }
        a = trange / frange;
        b = tmean - fmean * (trange / frange);
        [transform setValue:a Row:i Column:0];
        [transform setValue:b Row:i++ Column:1];
    }
    return transform;
}

@end
