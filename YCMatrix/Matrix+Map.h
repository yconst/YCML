//
//  Matrix+Map.h
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

#import <Foundation/Foundation.h>
#import "Matrix.h"

typedef enum _MapBasis : int16_t
{
    StDev = 1,
    MinMax = 0
} MapBasis;

typedef struct _YCDomain
{
    double location;
    double length;
} YCDomain;

static inline YCDomain YCMakeDomain(double loc, double len)
{
    YCDomain d;
    d.location = loc;
    d.length = len;
    return d;
}

static inline NSUInteger YCMaxDomain(YCDomain domain)
{
    return (domain.location + domain.length);
}

static inline BOOL YCNumberInDomain(double num, YCDomain domain)
{
    return (!(num < domain.location) && (num - domain.location) < domain.length) ? YES : NO;
}

static inline BOOL YCEqualDomains(YCDomain domain1, YCDomain domain2)
{
    return (domain1.location == domain2.location && domain1.length == domain2.length);
}

@interface Matrix (Map)

// Transform matrix |mtx| using transformation bi-vector |transform|
- (Matrix *)matrixByRowWiseMapUsing:(Matrix *)transform;

- (Matrix *)rowWiseMapToDomain:(YCDomain)domain basis:(MapBasis)basis;

- (Matrix *)rowWiseInverseMapFromDomain:(YCDomain)domain basis:(MapBasis)basis;

@end
