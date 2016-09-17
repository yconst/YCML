//
//  YCSMORegressionTrainer.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 11/12/15.
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

// N: Size of input
// S: Number of samples
// V: Support Vector count
// O: Size of output (for SVM-Regression O == 1)

#define SIGN(x) ((x > 0) - (x < 0))
#define STEP(x) (((x) < 0.0)? 0.0:1.0)

#define EPS 1E-8
#define TOL 1E-3

#import "YCSMORegressionTrainer.h"
#import "YCSVR.h"
#import "YCModelKernel.h"
#import "YCLinearKernel.h"
#import "YCRBFKernel.h"
#import "YCSMOCache.h"
@import YCMatrix;

@interface NSMutableOrderedSet (Shuffling)

- (void)shuffle;

@end

@implementation YCSMORegressionTrainer
{
    YCSMOCache *_cache;
    NSUInteger _datasetSize;
}

+ (Class)modelClass
{
    return [YCSVR class];
}

-(id)init
{
    if (self = [super init])
    {
        self.settings[@"C"]                 = @0.05;
        self.settings[@"Epsilon"]           = @0.01;
        self.settings[@"Kernel"]            = @"Linear"; // Linear, RBF
        self.settings[@"Beta"]              = @1.0; // For RBF kernels
    }
    return self;
}

- (YCSupervisedModel *)train:(YCSVR *)inputModel
                 inputMatrix:(Matrix *)input
                outputMatrix:(Matrix *)output
{
    // Input: One sample per column
    // Output: One sample per column
    // Input: NxS, output: OxS
    
    // Step I. Scaling inputs & outputs; determining inverse output scaling matrix
    YCDomain domain = YCMakeDomain(-1, 1);
    Matrix *inputTransform  = [input rowWiseMapToDomain:domain basis:MinMax];
    Matrix *outputTransform = [output rowWiseMapToDomain:domain basis:MinMax];
    Matrix *invOutTransform = [output rowWiseInverseMapFromDomain:domain basis:MinMax];
    Matrix *scaledInput     = [input matrixByRowWiseMapUsing:inputTransform];
    Matrix *scaledOutput    = [output matrixByRowWiseMapUsing:outputTransform];
    
    double C                = [self.settings[@"C"] doubleValue];
    double epsilon          = [self.settings[@"Epsilon"] doubleValue];
    double bias             = 0;
    int N                   = scaledInput.columns;
    int S                   = scaledInput.rows;
    int changed             = 0;
    BOOL examineAll         = YES;
    
    _datasetSize = N;
    
    Matrix *lambdas = [Matrix matrixOfRows:1 columns:N];
    
    YCSVR *model = inputModel ? inputModel : [YCSVR model];
    if (!model.kernel)
    {
        if ([self.settings[@"Kernel"] isEqualToString:@"RBF"])
        {
            model.kernel = [[YCRBFKernel alloc] init];
            model.kernel.properties[@"Beta"] = self.settings[@"Beta"];
        }
        else
        {
            model.kernel = [[YCLinearKernel alloc] init];
        }
    }
    
    NSMutableOrderedSet *order = [NSMutableOrderedSet orderedSet];
    for (int i = 0; i<N; i++)
    {
        [order addObject:@(i)];
    }
    
    // Step II. Starting SMO loop; identify potential Lagrange multipliers for updating
    
    while (changed > 0 || examineAll)
    {
        changed = 0;
        [order shuffle];
        
        if (examineAll)
        {
            for (NSNumber *number in order)
            {
                int i = [number intValue];
                changed += [self examine:i model:model input:scaledInput output:scaledOutput
                                 lambdas:lambdas order:order
                                       C:C bias:&bias epsilon:epsilon];
            }
        }
        else
        {
            for (NSNumber *number in order)
            {
                int i = [number intValue];
                double lambda = [lambdas i:0 j:i];
                if (ABS(lambda) > EPS || ABS(lambda) < C - EPS)
                {
                    changed += [self examine:i model:model input:scaledInput output:scaledOutput
                                     lambdas:lambdas order:order
                                           C:C bias:&bias epsilon:epsilon];
                }
            }
        }
        
        if (examineAll)
        {
            examineAll = NO;
        }
        else if (changed == 0)
        {
            examineAll = YES;
        }
    }
    
    // Step III. Transferring support vectors and coefficients to model
    NSMutableIndexSet *svIndexes = [NSMutableIndexSet indexSet];
    
    for (int i=0; i<N; i++)
    {
        if (ABS([lambdas i:0 j:i]) > EPS)
        {
            [svIndexes addIndex:i];
        }
    }
    
    Matrix *sv = [Matrix matrixOfRows:S columns:(int)svIndexes.count];
    Matrix *l = [Matrix matrixOfRows:1 columns:(int)svIndexes.count];
    
    __block int counter = 0;
    [svIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [sv setColumn:counter value:[scaledInput column:(int)idx]];
        [l i:0 j:counter set:[lambdas i:0 j:(int)idx]];
        counter++;
    }];
    
    model.sv = sv;
    model.lambda = l;
    model.b = bias;
    
    model.inputTransform = inputTransform;
    model.outputTransform = invOutTransform;

    return model;
}

- (int)examine:(int)idx1
          model:(YCSVR *)model
          input:(Matrix *)input
         output:(Matrix *)output
        lambdas:(Matrix *)lambdas
         order:(NSMutableOrderedSet *)order
              C:(double)C
           bias:(double *)bias
       epsilon:(double)epsilon
{
    @autoreleasepool
    {
        double lambda1 = [lambdas i:0 j:idx1];
        double e1 = [self errorForModel:model input:input output:output lambdas:lambdas
                                 exampleIndex:idx1 bias:*bias];
        
        // Check KKT conditions
        double r = ABS(e1);
        double a = ABS(lambda1);
        BOOL select = NO;
        if (r < epsilon - TOL && a > 0)
        {
            if ((epsilon - r + a / C) > 0) select = YES;
        }
        else if (r > epsilon + TOL && a < C)
        {
            if ((r - epsilon + (C - a) / C) > 0) select = YES;
        }
        
        if (!select) return 0;
        
        NSMutableOrderedSet *orderCopy = [order mutableCopy];
        [orderCopy shuffle];
        
        NSUInteger idx2 = NSNotFound;
        double maxErr = 0;
        for (NSNumber *n in orderCopy)
        {
            int ci = [n intValue];
            double e2 = [self errorForModel:model input:input output:output lambdas:lambdas
                                     exampleIndex:ci bias:*bias];
            if (ABS(e1 - e2) > maxErr)
            {
                maxErr = ABS(e1 - e2);
                idx2 = ci;
            }
        }
        
        if (idx2 != NSNotFound)
        {
            BOOL changed = [self step:model input:input output:output lambdas:lambdas
                               i1:idx1 i2:(int)idx2 bias:bias epsilon:epsilon C:C];
            if (changed) return 1;
        }
        
        for (NSNumber *n in orderCopy)
        {
            int idx2 = [n intValue];
            double lambda2 = [lambdas i:0 j:idx2];
            if (ABS(lambda2) <= EPS && ABS(lambda2) >= C - EPS)
            {
                continue;
            }
            BOOL changed = [self step:model input:input output:output lambdas:lambdas
                               i1:idx1 i2:idx2 bias:bias epsilon:epsilon C:C];
            if (changed) return 1;
        }
        
        for (NSNumber *n in orderCopy)
        {
            int idx2 = [n intValue];
            BOOL changed = [self step:model input:input output:output lambdas:lambdas
                               i1:idx1 i2:idx2 bias:bias epsilon:epsilon C:C];
            if (changed) return 1;
        }
        return 0;
    }
}

- (BOOL)step:(YCSVR *)model
       input:(Matrix *)input
      output:(Matrix *)output
     lambdas:(Matrix *)lambdas
          i1:(int)iu
          i2:(int)iv
        bias:(double *)bias
     epsilon:(double)epsilon
           C:(double)C
{
    if (iu == iv) return NO;
    
    double lambdauo = [lambdas i:0 j:iu];
    double lambdavo = [lambdas i:0 j:iv];
    
    if (lambdavo > lambdauo)
    {
        int ti = iu;
        iu = iv;
        iv = ti;
        
        double tlambda = lambdauo;
        lambdauo = lambdavo;
        lambdavo = tlambda;
    }
    
    double sum = lambdauo + lambdavo;
    
    double kuu = [[model.kernel kernelValueForA:[input column:iu] b:[input column:iu] ] i:0 j:0];
    //double kuu = [self kernelValueForModel:model input:input index:iu];
    double kuv = [[model.kernel kernelValueForA:[input column:iu] b:[input column:iv] ] i:0 j:0];
    //double kvv = [self kernelValueForModel:model input:input index:iv];
    double kvv = [[model.kernel kernelValueForA:[input column:iv] b:[input column:iv] ] i:0 j:0];
    
    double eta = kuu + kvv - 2*kuv;
    
    if (eta <= 0)
    {
        return NO;
    }
    
    double delta = 2 * epsilon / eta;
    
    double eu = [self errorForModel:model input:input output:output lambdas:lambdas
                             exampleIndex:iu bias:*bias];
    double ev = [self errorForModel:model input:input output:output lambdas:lambdas
                             exampleIndex:iv bias:*bias];
    
    double lambdav = lambdavo + (eu - ev) / eta;
    double lambdau = sum - lambdav;
    
    if (lambdau * lambdav < 0)
    {
        if (ABS(lambdav) >= delta || ABS(lambdau) >= delta)
        {
            lambdav = lambdav - SIGN(lambdav) * delta;
        }
        else
        {
            lambdav = STEP(ABS(lambdav) - ABS(lambdau)) * sum;
        }
    }
    
    double L = MAX(sum - C, -C);
    double H = MIN(C, sum + C);
    
    lambdav = MIN(MAX(lambdav, L), H);
    lambdau = sum - lambdav;
    
    if (ABS(lambdavo - lambdav) < EPS * (lambdav + lambdavo + EPS))
    {
        return NO;
    }

    double bu = -eu + (lambdauo - lambdau) * kuu + (lambdavo - lambdav) * kuv + *bias;
    double bv = -ev + (lambdauo - lambdau) * kuv + (lambdavo - lambdav) * kvv + *bias;
    double newb = (bu + bv) * 0.5;
    
    // Here check: did it actually improve the objective?
    double newEu = newb - bu;
    double newEv = newb - bv;
    
    double dobj = (epsilon * ABS(lambdau) + lambdau * (newEu - 0.5 * lambdau * kuu - newb) +
                   epsilon * ABS(lambdav) + lambdav * (newEv - 0.5 * lambdav * kvv - newb) -
                   lambdau * lambdav * kuv)
                   -
                   (epsilon * ABS(lambdauo) + lambdauo * (eu - 0.5 * lambdauo * kuu - *bias) +
                    epsilon * ABS(lambdavo) + lambdavo * (ev - 0.5 * lambdavo * kvv - *bias) -
                    lambdauo * lambdavo * kuv);
    
    if (dobj >= 0)
    {
        return NO;
    }
    
    [lambdas i:0 j:iu set:lambdau];
    [lambdas i:0 j:iv set:lambdav];
    
    *bias = newb;
        
    return YES;
}

- (double)errorForModel:(YCSVR *)model
                  input:(Matrix *)input
                 output:(Matrix *)output
                lambdas:(Matrix *)lambdas
           exampleIndex:(int)index
                   bias:(double)bias
{
    double f = [self outputForModel:model input:input lambdas:lambdas exampleIndex:index bias:bias];
    double y = [output i:0 j:index];
    double err = f - y;
    return err;
}

- (double)outputForModel:(YCSVR *)model
                  input:(Matrix *)input
                 lambdas:(Matrix *)lambdas
            exampleIndex:(int)index
                    bias:(double)bias
{
    Matrix *k = [model.kernel kernelValueForA:input b:[input column:index]];
    
    double o = 0.0;
    
    for (int i=0, n=(int)k.count; i<n; i++)
    {
        double l = [lambdas i:0 j:i];
        if (l == 0) continue;
        o += l * [k i:i j:0];
    }
    return o + bias;
}

#pragma mark – Accessors

- (YCSMOCache *)cache
{
    if (!_cache)
    {
        _cache = [[YCSMOCache alloc] initWithDatasetSize:_datasetSize cacheSize:200];
    }
    return _cache;
}

@end

@implementation NSMutableOrderedSet (Shuffling)

- (void)shuffle
{
    NSUInteger count = [self count];
    for (int i = 0; i < count; ++i)
    {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((int)remainingCount);
        [self exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

@end
