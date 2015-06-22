//
//  YCOLSPRESSTrainer.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 22/5/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
//

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
                                             Columns:1
                                               Value:basisFunctionWidth]; // -> Sx1
    model.centers             = [Matrix matrixFromMatrix:inp];// -> NxS
    
    // Find design matrix (aka regressor matrix) for full-sample width hidden layer (D == S => H:SxS)
    Matrix *P                 = [model calculateDesignMatrixWithInput:inp]; // -> SxS
    NSArray *PA               = [P columnsAsNSArray];
    
    // This will hold all the *orthogonalized* vectors up till the current (k) step
    NSMutableArray *W         = [NSMutableArray arrayWithCapacity:cols];
    
    // This will hold the subset of inputs selected as regressors.
    NSMutableArray *selectedRegressors = [[NSMutableArray alloc] init];
    
    // This will hold boolean values to denote whether an input has been selected as regressor.
    bool *isSelected          = calloc(cols, sizeof(bool));
    
    // Cache of all orthogonalized regressors of the last step
    NSMutableArray *lastOrtho = [NSMutableArray arrayWithArray:PA];
    
    // For PRESS: These will hold Ksi and B values for each step, for each regressor
    //YCMatrix *Ksi = [YCMatrix matrixFromMatrix:outp]; // OxS
    NSArray *KsiColumns       = [outp columnsAsNSArray];
    Matrix *B                 = [Matrix matrixOfRows:1 Columns:cols Value:1]; // 1xS
    
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
            Matrix *selectedB = [Matrix matrixOfRows:1 Columns:cols]; // 1xS
            
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
                    Matrix *currentB = [Matrix matrixOfRows:1 Columns:cols];
                    
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
                NSLog(@"Unable to select %ith regressor.", k);
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
            
            // Notify
            NSDictionary *netStats = @{@"Status"        : @"Forward Selection",
                                       @"Error"         : @(totalError),
                                       @"Step"          : @(k),
                                       @"Width"         : @(basisFunctionWidth)};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TrainingStep"
                                                                object:self
                                                              userInfo:netStats];
            
            // Break if maximum number of regressors reached
            if (maxRegressors > 0 && k > maxRegressors) break;
        }
    }
    // Here create a new matrix of selected regressors.
    Matrix *selectedRegressorMatrix = [Matrix matrixOfRows:inp->rows
                                                   Columns:(int)[selectedRegressors count]];
    int i = 0;
    for (Matrix *r in selectedRegressors)
    {
        [selectedRegressorMatrix setColumn:i++ Value:r];
    }
    
    model.centers = selectedRegressorMatrix;
    model.widths = [Matrix matrixOfRows:model.centers.columns
                                Columns:1
                                  Value:basisFunctionWidth];
    
    // Assign network statistics dictionary
    model.statistics[@"Error"]      = @(totalError);
    model.statistics[@"Regressors"] = @([selectedRegressors count]);
    
    // Clean up
    free(isSelected);
}

@end
