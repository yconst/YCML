//
//  YCSMORegressionTrainer.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 11/12/15.
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

// N: Size of input
// S: Number of samples
// V: Support Vector count
// O: Size of output (for SVM-Regression O == 1)

#define SIGN(x) ((x > 0) - (x < 0))
#define STEP(x) (((x) < 0.0)? 0.0:1.0)


#import "YCSMORegressionTrainer.h"
#import "YCSVR.h"

@implementation YCSMORegressionTrainer
{
    Matrix *_kernelCache;
}

+ (Class)modelClass
{
    return [YCSVR class];
}

-(id)init
{
    if (self = [super init])
    {
        self.settings[@"C"]                 = @0.01;
        self.settings[@"Epsilon"]           = @0.01; // epsilon-insensitive zone
        self.settings[@"Passes"]            = @10;
        self.settings[@"Max Iterations"]    = @2000;
        self.settings[@"Tolerance"]         = @1E-3; // KKT numerical tolerance
        self.settings[@"Alpha Tolerance"]   = @1E-8;
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
    YCDomain domain = YCMakeDomain(0, 1);
    Matrix *inputTransform  = [input rowWiseMapToDomain:domain basis:StDev];
    Matrix *outputTransform = [output rowWiseMapToDomain:domain basis:MinMax];
    Matrix *invOutTransform = [output rowWiseInverseMapFromDomain:domain basis:MinMax];
    Matrix *scaledInput     = [input matrixByRowWiseMapUsing:inputTransform];
    Matrix *scaledOutput    = [output matrixByRowWiseMapUsing:outputTransform];
    
    double bias             = 0;
    double aTolerance       = [self.settings[@"Alpha Tolerance"] doubleValue];
    int passes              = [self.settings[@"Passes"] intValue];
    int iterations          = [self.settings[@"Max Iterations"] intValue];
    int N                   = scaledInput.columns;
    int S                   = scaledInput.rows;
    
    _kernelCache = [Matrix matrixOfRows:N columns:1 value:DBL_MIN];
    
    Matrix *lambdas = [Matrix matrixOfRows:1 columns:scaledInput.columns];
    YCSVR *model = inputModel ? inputModel : [YCSVR model];
    if (!model.kernel) model.kernel = [[YCLinearKernel alloc] init];
    
    NSMutableIndexSet *workingSet = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, N)];
    
    while (passes > 0 && iterations > 0)
    {
        BOOL c = [self pass:model
                      input:scaledInput
                     output:scaledOutput
                    lambdas:lambdas
                       bias:&bias
                 workingSet:workingSet];
        if (c) passes--;
        iterations--;
    }
    
    NSMutableIndexSet *svIndexes = [NSMutableIndexSet indexSet];
    
    for (int i=0; i<N; i++)
    {
        if (ABS([lambdas i:0 j:i]) > aTolerance)
        {
            [svIndexes addIndex:i];
        }
    }
    
    Matrix *sv = [Matrix matrixOfRows:S columns:(int)svIndexes.count];
    Matrix *w = [Matrix matrixOfRows:(int)svIndexes.count columns:1];
    
    __block int counter = 0;
    [svIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [sv setColumn:counter value:[scaledInput column:(int)idx]];
        [w i:counter j:0 set:[lambdas i:0 j:(int)idx]];
        counter++;
    }];
    
    model.sv = sv;
    model.w = w;
    model.b = bias;
    
    model.inputTransform = inputTransform;
    model.outputTransform = invOutTransform;

    return model;
}

- (BOOL)pass:(YCSVR *)model
       input:(Matrix *)input
      output:(Matrix *)output
     lambdas:(Matrix *)lambdas
        bias:(double *)bias
  workingSet:(NSMutableIndexSet *)workingSet
{
    // Working variables
    __block int aChange = 0;
    double C = [self.settings[@"C"] doubleValue];
    
    // Establish an index set to place indexes that need to be removed
    NSMutableIndexSet *remove = [NSMutableIndexSet indexSet];
    
    // Go through the working set first
    [workingSet enumerateIndexesUsingBlock:^(NSUInteger idx1, BOOL * _Nonnull stop) {
        
        NSUInteger idx2 = [self randomIndexInIndexSet:workingSet];
        
        BOOL change = [self step:model input:input output:output
                         lambdas:lambdas i1:(int)idx1 i2:(int)idx2 bias:bias C:C];
        
        if (change) aChange++;
        
        double l1 = [lambdas i:0 j:(int)idx1];
        double l2 = [lambdas i:0 j:(int)idx2];
        
        if (ABS(l1) == C || 0 == l1)
        {
            [remove addIndex:idx1];
        }
        if (ABS(l2) == C || 0 == l2)
        {
            [remove addIndex:idx2];
        }
    }];
    
    // Remove the relevant indexes
    [workingSet removeIndexes:remove];
    
    // Establish an index set to replace indexes that need to be added
    NSMutableIndexSet *add = [NSMutableIndexSet indexSet];
    
    // If there is no change, check the whole array
    if (0 == aChange)
    {
        for (int idx1=0, n=input.columns; idx1<n; idx1++)
        {
            int idx2 = arc4random_uniform(n);
            BOOL change = [self step:model input:input output:output
                             lambdas:lambdas i1:idx1 i2:idx2 bias:bias C:C];
            if (change) aChange++;
            
            double l1 = [lambdas i:0 j:(int)idx1];
            double l2 = [lambdas i:0 j:(int)idx2];
            
            if (ABS(l1) != C && 0 != l1)
            {
                [add addIndex:idx1];
            }
            if (ABS(l2) != C && 0 != l2)
            {
                [add addIndex:idx2];
            }
        }
    }
    
    [workingSet addIndexes:add];
    
    return (0 == aChange);
}

- (BOOL)step:(YCSVR *)model
       input:(Matrix *)input
      output:(Matrix *)output
     lambdas:(Matrix *)lambdas
          i1:(int)iu
          i2:(int)iv
        bias:(double *)bias
           C:(double)C
{
    @autoreleasepool
    {
        double luStar = [lambdas i:0 j:iu];
        double lvStar = [lambdas i:0 j:iv];
        double sStar = luStar + lvStar;
        
        double kuu = [self kernelValueForModel:model input:input index:iu];
        double kuv = [[model.kernel kernelValueForA:[input column:iu] b:[input column:iv] ] i:0 j:0];
        double kvv = [self kernelValueForModel:model input:input index:iv];
        
        // Positive definite kernel is assumed
        double eta = kuu + kvv - 2.0 * kuv;
        if (eta <= 0)
        {
            return NO;
        }
        
        double epsilon = [self.settings[@"Epsilon"] doubleValue];
        double delta = 2 * epsilon / eta;
        
        double fu = [self outputForModel:model input:input lambdas:lambdas exampleIndex:iu bias:*bias];
        double fv = [self outputForModel:model input:input lambdas:lambdas exampleIndex:iv bias:*bias];
        double yu = [output i:0 j:iu];
        double yv = [output i:0 j:iv];
        
        double lv = lvStar + (yv - yu + fu - fv) / eta;
        double lu = sStar - lv;
        
        if  (lu*lv < 0)
        {
            if (ABS(lv) >= delta || ABS(lu) >= delta)
            {
                lv = lv - SIGN(lv) * delta;
            }
            else
            {
                lv = STEP(ABS(lv) - ABS(lu)) * sStar;
            }
        }
        
        double L = MAX(sStar - C, -C);
        double H = MIN(C, sStar + C);
        
        lv = MIN(MAX(lv, L), H);
        lu = sStar - lv;
        
        double tolerance = [self.settings[@"Tolerance"] doubleValue];
        if (ABS(ABS(lv) - ABS(lvStar)) < tolerance * (ABS(lv) + ABS(lvStar) + tolerance))
        {
            return NO;
        }
        
        [lambdas i:0 j:iu set:lu];
        [lambdas i:0 j:iv set:lv];
        
        //L = MAX(sStar - C, -C);
        //H = MIN(C, sStar + C);
        
        double bu = yu - fu + (luStar - lu) * kuu + (lvStar - lv) * kuv + *bias;
        double bv = yv - fv + (luStar - lu) * kuv + (lvStar - lv) * kvv + *bias;
        
        *bias = (bu + bv) * 0.5;
        
        return YES;
    }
    
}

-(double)outputForModel:(YCSVR *)model
                 input:(Matrix *)input
                lambdas:(Matrix *)lambdas
           exampleIndex:(int)index
                   bias:(double)bias
{
    // 1. Calculate kernel
    Matrix *k = [model.kernel kernelValueForA:input b:[input column:index]];
    
    // 2. Multiply with lagrange multipliers
    [k elementWiseMultiply:[lambdas matrixByTransposing]];
    
    // 3. Sum up and add bias
    Matrix *output = [k sumsOfColumns];
    [output addColumn:[Matrix matrixOfRows:1 columns:1 value:bias]];
    
    return [output i:0 j:0];
}

- (double)kernelValueForModel:(YCSVR *)model input:(Matrix *)input index:(int)index
{
    if (DBL_MIN == [_kernelCache i:index j:0])
    {
        Matrix *column = [input column:index];
        double newValue = [[model.kernel kernelValueForA:column b:column] i:0 j:0];
        [_kernelCache i:index j:0 set:newValue];
        return newValue;
    }
    return [_kernelCache i:index j:0];
}

- (NSUInteger)randomIndexInIndexSet:(NSIndexSet *)indexSet {
    NSUInteger xth = arc4random() % [indexSet count];
    __block NSUInteger ith = 0;
    __block NSUInteger result = NSNotFound;
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (ith == xth) {
            result = idx;
            *stop = YES;
        }
        ith++;
    }];
    
    return result;
}

@end
