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
    Matrix *_transposedInput;
    NSUInteger _globalChange;
    NSUInteger _iul;
    NSUInteger _ivl;
    double _dul;
    double _dvl;
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
        self.settings[@"Disable Cache"]     = @NO;
        self.settings[@"Cache Size"]        = @300;
    }
    return self;
}

- (void)performTrainingModel:(YCSVR *)model
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
    
    _transposedInput = [scaledInput matrixByTransposing];
    if ([self.settings[@"Disable Cache"] boolValue])
    {
        NSUInteger cacheSize = MIN([self.settings[@"Cache Size"] unsignedIntValue],
                                   scaledInput.columns);
        _cache = [[YCSMOCache alloc] initWithDatasetSize:scaledInput.columns
                                               cacheSize:cacheSize];
    }
    
    Matrix *lambdas = [Matrix matrixOfRows:1 columns:N];
    Matrix *previousOutputs = [Matrix matrixOfRows:1 columns:N value:0];
    Matrix *lastModified = [Matrix matrixOfRows:1 columns:N value:_globalChange];
    
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
                if ([self examine:i model:model input:scaledInput output:scaledOutput
                                 lambdas:lambdas previousOutputs:previousOutputs
                            lastModified:lastModified order:order
                                       C:C bias:&bias epsilon:epsilon useFullSetRules:NO])
                {
                    changed++;
                    _globalChange++;
                }
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
                    if ([self examine:i model:model input:scaledInput output:scaledOutput
                                     lambdas:lambdas previousOutputs:previousOutputs
                                lastModified:lastModified order:order
                                           C:C bias:&bias epsilon:epsilon useFullSetRules:YES])
                    {
                        changed++;
                        _globalChange++;
                    }
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
    
    // Cleanup
    _cache = nil;
    _globalChange = 0;
    _transposedInput = nil;
    
    _iul = 0;
    _ivl = 0;
    _dul = 0;
    _dvl = 0;
}

- (BOOL)examine:(int)idx1
          model:(YCSVR *)model
          input:(Matrix *)input
         output:(Matrix *)output
        lambdas:(Matrix *)lambdas
previousOutputs:(Matrix *)previousOutputs
   lastModified:(Matrix *)lastModified
          order:(NSMutableOrderedSet *)order
              C:(double)C
           bias:(double *)bias
        epsilon:(double)epsilon
useFullSetRules:(BOOL)fullSetRules
{
    @autoreleasepool
    {
        BOOL tickle = !fullSetRules;
        double lambda1 = [lambdas i:0 j:idx1];
        double e1 = [self errorForModel:model input:input target:output lambdas:lambdas
                           previousOutputs:previousOutputs lastModified:lastModified
                           exampleIndex:idx1 bias:*bias tickleCache:tickle];
        
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
        
        if (!select) return NO;
        
        NSMutableOrderedSet *orderCopy = [order mutableCopy];
        [orderCopy shuffle];
        
        NSUInteger idx2 = NSNotFound;
        double maxErr = 0;
        for (NSNumber *n in orderCopy)
        {
            int ci = [n intValue];
            double e2 = [self errorForModel:model input:input target:output lambdas:lambdas
                               previousOutputs:previousOutputs lastModified:lastModified
                               exampleIndex:ci bias:*bias tickleCache:tickle];
            if (ABS(e1 - e2) > maxErr)
            {
                maxErr = ABS(e1 - e2);
                idx2 = ci;
            }
        }
        
        if (idx2 != NSNotFound)
        {
            BOOL changed = [self step:model input:input output:output lambdas:lambdas
                         previousOutputs:previousOutputs lastModified:lastModified
                                   i1:idx1 i2:(int)idx2 bias:bias epsilon:epsilon C:C
                          tickleCache:tickle];
            if (changed) return YES;
        }
        
        for (NSNumber *n in orderCopy)
        {
            int idx2 = [n intValue];
            double lambda2 = [lambdas i:0 j:idx2];
            if (fullSetRules == NO && ABS(lambda2) <= EPS && ABS(lambda2) >= C - EPS)
            {
                continue;
            }
            BOOL changed = [self step:model input:input output:output lambdas:lambdas
                         previousOutputs:previousOutputs lastModified:lastModified
                                   i1:idx1 i2:idx2 bias:bias epsilon:epsilon C:C
                          tickleCache:tickle];
            if (changed) return YES;
        }

        return NO;
    }
}

- (BOOL)step:(YCSVR *)model
       input:(Matrix *)input
      output:(Matrix *)output
     lambdas:(Matrix *)lambdas
previousOutputs:(Matrix *)previousOutputs
lastModified:(Matrix *)lastModified
          i1:(int)iu
          i2:(int)iv
        bias:(double *)bias
     epsilon:(double)epsilon
           C:(double)C
 tickleCache:(BOOL)tickle
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
    
    double kuu = [self kernelValueForA:iu B:iu input:input model:model tickle:tickle replace:tickle];
    double kuv = [self kernelValueForA:iu B:iv input:input model:model tickle:tickle replace:tickle];
    double kvv = [self kernelValueForA:iv B:iv input:input model:model tickle:tickle replace:tickle];
    
    double eta = kuu + kvv - 2*kuv;
    
    if (eta <= 0)
    {
        return NO;
    }
    
    double delta = 2 * epsilon / eta;
    
    double eu = [self errorForModel:model input:input target:output lambdas:lambdas
                    previousOutputs:previousOutputs lastModified:lastModified
                       exampleIndex:iu bias:*bias tickleCache:tickle];
    double ev = [self errorForModel:model input:input target:output lambdas:lambdas
                    previousOutputs:previousOutputs lastModified:lastModified
                       exampleIndex:iv bias:*bias tickleCache:tickle];
    
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
    
    double du = lambdau - lambdauo;
    double dv = lambdav - lambdavo;
    
    if (ABS(dv) < EPS * (lambdav + lambdavo + EPS))
    {
        return NO;
    }

    double bu = -eu - du * kuu - dv * kuv + *bias;
    double bv = -ev - du * kuv - dv * kvv + *bias;
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
    
    _iul = iu;
    _ivl = iv;
    _dul = du;
    _dvl = dv;
        
    return YES;
}

- (double)errorForModel:(YCSVR *)model
                  input:(Matrix *)input
                 target:(Matrix *)output
                lambdas:(Matrix *)lambdas
        previousOutputs:(Matrix *)previousOutputs
           lastModified:(Matrix *)lastModified
           exampleIndex:(int)index
                   bias:(double)bias
            tickleCache:(BOOL)tickle
{
    double f = [self outputForModel:model input:input lambdas:lambdas
                    previousOutputs:previousOutputs lastModified:lastModified
                       exampleIndex:index bias:bias tickleCache:tickle];
    double y = [output i:0 j:index];
    double err = f - y;
    return err;
}

- (double)outputForModel:(YCSVR *)model
                  input:(Matrix *)input
                 lambdas:(Matrix *)lambdas
         previousOutputs:(Matrix *)previousOutputs
            lastModified:(Matrix *)lastModified
            exampleIndex:(int)index
                    bias:(double)bias
             tickleCache:(BOOL)tickle
{
    double output;
    if (lastModified && [lastModified i:0 j:index] == _globalChange)
    {
        // 12% decrease in CPU time (p<0.001)
        output = [previousOutputs i:0 j:index];
    }
    else if (lastModified && [lastModified i:0 j:index] == _globalChange - 1)
    {
        // 70% decrease in CPU time (p<0.001)
        double po = [previousOutputs i:0 j:index];
        double ku = [self kernelValueForA:_iul B:index input:input model:model
                                 tickle:tickle replace:tickle];
        double kv = [self kernelValueForA:_ivl B:index input:input model:model
                                 tickle:tickle replace:tickle];
        output = po + ku * _dul + kv * _dvl;
        
        [previousOutputs i:0 j:index set:output];
        [lastModified i:0 j:index set:_globalChange];
    }
    else
    {
        Matrix *k = [model.kernel kernelValueForA:input b:[input column:index]];
        
        double o = 0.0;
        
        for (int i=0, n=(int)k.count; i<n; i++)
        {
            double l = [lambdas i:0 j:i];
            if (l == 0) continue;
            o += l * [k i:i j:0];
        }
        output = o;
        
        [previousOutputs i:0 j:index set:o];
        [lastModified i:0 j:index set:_globalChange];
    }
    return output + bias;
}

#pragma mark - Cache

- (double)kernelValueForA:(NSUInteger)a B:(NSUInteger)b input:(Matrix *)input
                    model:(YCSVR *)model tickle:(BOOL)tickle replace:(BOOL)replace
{
    if (self.cache && [self.cache queryI:a j:b] == included)
    {
        return [self.cache getI:a j:b tickle:tickle];
    }
    
    Matrix *aVector, *bVector;
    if (_transposedInput)
    {
        aVector = [_transposedInput rowReferenceVector:(int)a];
        bVector = [_transposedInput rowReferenceVector:(int)b];
    }
    else
    {
        aVector = [input column:(int)a];
        bVector = [input column:(int)b];
    }
    
    double val = [[model.kernel kernelValueForA:aVector b:bVector] i:0 j:0];
    if (self.cache && replace)
    {
        [self.cache setI:a j:b value:val];
    }
    return val;
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
