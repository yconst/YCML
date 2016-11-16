//
//  YCOLSTrainer.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 22/4/15.
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

#import "YCOLSTrainer.h"
#import "YCRBFNet.h"
@import YCMatrix;

@implementation YCOLSTrainer

+ (Class)modelClass
{
    return [YCRBFNet class];
}

-(id)init
{
    if (self = [super init])
    {
        self.settings[@"Kernel Width"]    = @2;
        self.settings[@"Error Tolerance"] = @0.02;
        self.settings[@"Max Regressors"]  = @300;
        self.settings[@"Lambda"] = @0;
    }
    return self;
}

- (void)performTrainingModel:(YCRBFNet *)model
                 inputMatrix:(Matrix *)input
                outputMatrix:(Matrix *)output
{
    // Input: NxS, output: OxS
    // Step I. Scaling inputs & outputs; determining inverse output scaling matrix
    YCDomain domain = YCMakeDomain(-1, 2);
    model.inputTransform = [input rowWiseMapToDomain:domain basis:StDev];
    Matrix *outputScaling = [output rowWiseMapToDomain:domain basis:StDev];
    model.outputTransform = [output rowWiseInverseMapFromDomain:domain basis:StDev];
    
    Matrix *scaledInput = [input matrixByRowWiseMapUsing:model.inputTransform];
    Matrix *scaledOutput = [output matrixByRowWiseMapUsing:outputScaling];
    
    // Step II. Determining Centers and Widths
    if (self.delegate && [self.delegate respondsToSelector:@selector(stepComplete:)])
    {
        [self.delegate stepComplete:@{@"Status" : @"Initializing Regressor Selection"}];
    }
    
    [self centersAndWidthsFor:model input:scaledInput output:scaledOutput];
    
    // Step III. Determining Output (Linear) Weights -> DxO
    if (self.delegate && [self.delegate respondsToSelector:@selector(stepComplete:)])
    {
        [self.delegate stepComplete:@{@"Status" : @"Calculating Output Weights"}];
    }
    
    [self weightsFor:model input:scaledInput output:scaledOutput];
}

- (void)centersAndWidthsFor:(YCRBFNet *)model input:(Matrix *)inp output:(Matrix *)outp
{
    double tolerance          = [[self.settings objectForKey:@"Error Tolerance"] doubleValue];
    double totalError         = 1;
    double cols               = inp->columns; // == S
    double basisFunctionWidth = [[self.settings objectForKey:@"Kernel Width"] doubleValue];
    int maxRegressors         = [self.settings[@"Max Regressors"] intValue];
    double lambda             = [self.settings[@"Lambda"] doubleValue];
    // inp -> NxS
    model.widths              = [Matrix matrixOfRows:cols
                                               columns:1
                                                 value:basisFunctionWidth]; // -> Sx1
    model.centers             = [Matrix matrixFromMatrix:inp];// -> NxS
    
    // Explode output rows as NSArrays
    NSArray *OA               = [outp rowsAsNSArray];
    
    // Find the trace of the output matrix
    double dTrace             = [[outp matrixByMultiplyingWithRight:[outp matrixByTransposing]] trace];
    
    // This will hold all the *orthogonalized* vectors up till the current (k) step
    NSMutableArray *W         = [NSMutableArray array];
    
    // This will hold the subset of inputs selected as regressors.
    NSMutableArray *selectedRegressors = [[NSMutableArray alloc] init];
    
    // This will hold boolean values to denote whether an input has been selected as regressor.
    bool *isSelected          = calloc(cols, sizeof(bool));
    
    // Find design matrix (aka regressor matrix) for full-sample width hidden layer (D == S => H:SxS)
    // Cache of all orthogonalized regressors of the last step
    NSMutableArray *lastOrtho;
    @autoreleasepool {
        lastOrtho = [[[self initialDesignMatrixWithInput:inp widths:model.widths]
                      columnsAsNSArray] mutableCopy];
    }
    
    for (int k=0; k<cols; k++)
    {
        @autoreleasepool
        {
            int maxERRIndex = -1;
            double maxERR = -1;
            Matrix *currentW;
            
            // Select last selected orthonormal regressor
            Matrix *wl = [W lastObject];
            
            // Here select the next regressor
            for (int i=0; i<cols; i++)
            {
                if (isSelected[i]) continue;
                @autoreleasepool
                {
                    // Select i-th regressor's orthogonal P-column
                    Matrix *wki = lastOrtho[i];
                    
                    // Orthogonalize to last orthonormal P-vector
                    if (wl)
                    {
                        double a = [wl dotWith:wki]/[wl dotWith:wl];
                        wki = [wki matrixBySubtracting:[wl matrixByMultiplyingWithScalar: a]];
                        lastOrtho[i] = wki;
                    }
                    
                    double wkiwki = [wki dotWith:wki];
                    
                    // Calculate ERR (= Error Reduction Ratio)
                    
                    double sumg2 = 0;
                    
                    // Check how much the regressor contributes to each output
                    for (Matrix *o in OA)
                    {
                        double gki = [wki dotWith:o]/wkiwki;
                        sumg2 += gki*gki;
                    }
                    
                    double ERR = (sumg2*(wkiwki + lambda))/dTrace;
                    
                    // If the current ERR is larger than the max ERR, select this regressor.
                    if (ERR > maxERR)
                    {
                        maxERRIndex = i;
                        maxERR = ERR;
                        currentW = wki;
                    }
                }
            }
            
            // Check if a regressor has been selected
            if (maxERRIndex < 0)
            {
                NSLog(@"Unable to select %ith regressor", k);
                break;
            }
            
            // If yes, update isSelected and W
            isSelected[maxERRIndex] = true;
            [W addObject:currentW];
            
            // Here add the real regressor! From the inp matrix!
            [selectedRegressors addObject:[inp column:maxERRIndex]];
            
            // Update error
            totalError -= maxERR;
            
            // Notify delegate
            if (self.delegate && [self.delegate respondsToSelector:@selector(stepComplete:)])
            {
                NSDictionary *info = @{@"Status"        : @"Forward Selection",
                                       @"Error"         : @(totalError),
                                       @"Step"          : @(k),
                                       @"Width"         : @(basisFunctionWidth)};
                [self.delegate stepComplete:info];
            }
            
            // Break if tolerance is reached or stopping command is issued
            if (totalError <= tolerance || self.shouldStop) break;
            
            // Break if maximum number of regressors reached
            if (maxRegressors > 0 && k > maxRegressors) break;
        }
    }
    
    // Here create a new matrix of selected regressors.
    Matrix *selectedRegressorMatrix = [Matrix matrixOfRows:inp->rows
                                                   columns:(int)[selectedRegressors count]];
    int i = 0;
    for (Matrix *r in selectedRegressors)
    {
        [selectedRegressorMatrix setColumn:i++ value:r];
    }
    
    model.centers = selectedRegressorMatrix;
    model.widths = [Matrix matrixOfRows:model.centers.columns
                                columns:1
                                  value:basisFunctionWidth];
    
    // Assign network statistics dictionary
    model.statistics[@"Error"]      = @(totalError);
    model.statistics[@"Regressors"] = @([selectedRegressors count]);
    
    // Clean up
    free(isSelected);
}

- (void)weightsFor:(YCRBFNet *)model input:(Matrix *)input output:(Matrix *)output
{
    // O = H * W => W = H^-1 * O
    Matrix *H     = [model designMatrixWithInput:input];
    H             = [H appendColumn:[Matrix matrixOfRows:H->rows columns:1 value:1]]; // Augment with bias
    Matrix *Hinv  = [H pseudoInverse];
    Matrix *W     = [Hinv matrixByMultiplyingWithRight:[output matrixByTransposing]];
    model.weights = W;
}

- (Matrix *)initialDesignMatrixWithInput:(Matrix *)input widths:(Matrix *)widths
{
    NSAssert(widths.rows == input.columns, @"Widths need to have same number of rows as input matrix");
    int N = input->rows;
    int S = input->columns;
    
    // Generate design matrix of dimensions SxS
    Matrix *designmatrix = [Matrix matrixOfRows:S columns:S];
    
    // Fill up the design matrix, traversing first row and then column
    dispatch_apply(S, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i)
                   {
                       @autoreleasepool {
                           for (size_t j=i; j<S; j++)
                           {
                               if (i == j)
                               {
                                   designmatrix->matrix[i*(S + 1)] = 1;
                                   continue;
                               }
                               double sqsum = 0;
                               double val;
                               for (int k=0; k<N; k++)
                               {
                                   val = input->matrix[k*S + i] - input->matrix[k*S + j];
                                   sqsum += val*val;
                               }
                               double bfvalue = exp( - sqsum / pow(widths->matrix[j], 2));
                               
                               bfvalue =
                               
                               designmatrix->matrix[i*S + j] = bfvalue;
                               designmatrix->matrix[j*S + i] = bfvalue;
                           }
                       }
                   });
    return designmatrix;
}

@end
