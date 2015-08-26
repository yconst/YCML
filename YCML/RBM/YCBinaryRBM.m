//
//  YCBinaryRBM.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 30/7/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCBinaryRBM.h"

// N: Size of input
// S: Number of samples
// H: Size of hidden layer

// Weights, W: HxN
// Visible biases, b: Nx1
// Hidden biases, c: Hx1

// Input: Nx1

@implementation YCBinaryRBM

- (Matrix *)prePropagateToHidden:(Matrix *)visible
{
    Matrix *ret = [self.weights matrixByMultiplyingWithRight:visible]; // HxN * NxS = HxS
    [ret addColumn:self.hiddenBiases];
    return ret;
}

- (Matrix *)prePropagateToVisible:(Matrix *)hidden
{
    Matrix *ret = [self.weights matrixByTransposingAndMultiplyingWithRight:hidden]; // (HxN)T * HxS = NxS
    [ret addColumn:self.visibleBiases];
    return ret;
}

- (Matrix *)propagateToHidden:(Matrix *)visible
{
    Matrix *ret = [self prePropagateToHidden:visible];
    [ret applyFunction:^double(double value) {
        return 1.0 / (1.0 + exp(-value));
    }];
    return ret;
}

- (Matrix *)propagateToVisible:(Matrix *)hidden
{
    Matrix *ret = [self prePropagateToVisible:hidden];
    [ret applyFunction:^double(double value) {
        return 1.0 / (1.0 + exp(-value));
    }];
    return ret;
}

- (Matrix *)sampleHiddenGivenVisible:(Matrix *)visible
{
    Matrix *hidden = [self propagateToHidden:visible];
    [hidden bernoulli];
    return hidden;
}

- (Matrix *)sampleVisibleGivenHidden:(Matrix *)hidden
{
    Matrix *visible = [self propagateToVisible:hidden];
    [visible bernoulli];
    return visible;
}

- (Matrix *)freeEnergy:(Matrix *)visible
{
    // visible: NxS
    Matrix *wxb = [self prePropagateToHidden:visible]; // HxN * NxS = HxS (wxb)
    [wxb applyFunction:^double(double value) { return log(1 + exp(value)); }];
    Matrix *hidden = [wxb sumsOfColumns]; // 1xS (hidden)
    
    Matrix *negativeVisible = [self.visibleBiases matrixByTransposingAndMultiplyingWithRight:visible]; // (Nx1)T * NxS = 1xS (vBias)
    
    [negativeVisible add:hidden]; // hidden + vbias
    [negativeVisible negate]; // - hidden - vbias
    return negativeVisible; // 1xS
}

- (int)visibleSize
{
    return self.weights.columns;
}

- (int)hiddenSize
{
    return self.weights.rows;
}

@end
