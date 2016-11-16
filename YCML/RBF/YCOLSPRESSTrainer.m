//
//  YCOLSPRESSTrainer.m
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

#import "YCOLSPRESSTrainer.h"
#import "YCRBFNet.h"
@import YCMatrix;

@implementation YCOLSPRESSTrainer

-(id)init
{
    if (self = [super init])
    {
        [self.settings removeObjectForKey:@"Error Tolerance"];
    }
    return self;
}

- (void)centersAndWidthsFor:(YCRBFNet *)model input:(Matrix *)inp output:(Matrix *)outp
{
    double totalError         = 1;
    double cols               = inp->columns; // == S
    double outputSize         = outp->rows; // == O
    double basisFunctionWidth = [[self.settings objectForKey:@"Kernel Width"] doubleValue];
    int maxRegressors         = [self.settings[@"Max Regressors"] intValue];
    // inp -> NxS
    model.widths              = [Matrix matrixOfRows:cols
                                             columns:1
                                               value:basisFunctionWidth]; // -> Sx1
    model.centers             = [Matrix matrixFromMatrix:inp];// -> NxS
    
    // This will hold all the *orthogonalized* vectors up till the current (k) step
    NSMutableArray *W         = [NSMutableArray arrayWithCapacity:cols];
    
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
    
    // For PRESS: These will hold Ksi and B values for each step, for each regressor
    //YCMatrix *Ksi = [YCMatrix matrixFromMatrix:outp]; // OxS
    NSArray *KsiColumns       = [outp columnsAsNSArray];
    Matrix *B                 = [Matrix matrixOfRows:1 columns:cols value:1]; // 1xS
    
    double prevJki            = [[outp matrixByMultiplyingWithRight:[outp matrixByTransposing]] trace];
    
    
    for (int k=0; k<cols; k++)
    {
        @autoreleasepool
        {
            int chosenRegressorIndex = -1;
            double minJki = DBL_MAX;
            Matrix *currentW;
            
            // Select last selected orthonormal regressor
            Matrix *wl = [W lastObject];
            double wlwl = [wl dotWith:wl];
            
            // Better to have an array of columns, so only pointers are exchanged
            NSMutableArray *selectedKsiColumns = [NSMutableArray arrayWithCapacity:cols]; // OxS
            Matrix *selectedB = [Matrix matrixOfRows:1 columns:cols]; // 1xS
            
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
                        double a = [wl dotWith:wki]/wlwl;
                        // = wki - a*wl
                        wki = [wl matrixByMultiplyingWithScalar:-a AndAdding:wki];
                        lastOrtho[i] = wki;
                    }
                    
                    double kki = [wki dotWith:wki];
                    double oneOverKki = 1/kki;
                    
                    // OxS * Sx1 => Ox1
                    Matrix *gammaki = [outp matrixByMultiplyingWithRight:wki AndFactor:oneOverKki];
                    
                    // Calculate PRESS (= predicted-residual-sums-of-squares)
                    // OxS, 1xS
                    NSMutableArray *currentKsiColumns = [NSMutableArray arrayWithCapacity:cols];
                    Matrix *currentB = [Matrix matrixOfRows:1 columns:cols];
                    
                    double *BMatrix = B->matrix;
                    double *currentBMatrix = currentB->matrix;
                    double *wkiMatrix = wki->matrix;
                    
                    double Jki = 0;
                    
                    for (int t=0; t<cols; t++)
                    {
                        double wkit = wkiMatrix[t];
                        
                        // = Ksi(t) - gk*wkit (Ox1)
                        Matrix *Ksit = [gammaki matrixByMultiplyingWithScalar:-wkit AndAdding:KsiColumns[t]];
                        
                        double Bt = BMatrix[t] - (wkit*wkit) * oneOverKki;
                        
                        double KsitKsit = [Ksit dotWith:Ksit];
                        Jki += KsitKsit/(Bt*Bt);
                        
                        // Break early if we are not interested in this regressor
                        // to save some CPU cycles. currentKsi and currentB won't be used in this
                        // case anyway.
                        if (Jki >= minJki) break;
                        
                        [currentKsiColumns addObject:Ksit];
                        currentBMatrix[t] = Bt;
                    }
                    
                    // If the current Jki is smaller than the min Jki, select this regressor.
                    if (Jki < minJki)
                    {
                        chosenRegressorIndex = i;
                        minJki = Jki;
                        currentW = wki;
                        selectedKsiColumns = currentKsiColumns;
                        selectedB = currentB;
                    }
                }
            }
            
            // Check if a regressor has been selected
            if (chosenRegressorIndex < 0)
            {
                NSLog(@"Unable to select %ith regressor", k);
                break;
            }
            
            double aminJki = minJki / (cols*outputSize);
            
            // If there is no improvement or a stopping command is issued, break
            if (aminJki >= prevJki || self.shouldStop) break;
            
            // Otherwise, update Ksi, B, Jki, isSelected and W
            KsiColumns = selectedKsiColumns;
            B = selectedB;
            prevJki = aminJki;
            isSelected[chosenRegressorIndex] = true;
            [W addObject:currentW];
            
            // Here add the real regressor and associated width!
            [selectedRegressors addObject:[model.centers column:chosenRegressorIndex]];
            
            // Notify delegate
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(stepComplete:)])
            {
                NSDictionary *info = @{@"Status"        : @"Forward Selection",
                                       @"Error"         : @(totalError),
                                       @"Step"          : @(k),
                                       @"Width"         : @(basisFunctionWidth)};
                [self.delegate stepComplete:info];
            }
            
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

@end
