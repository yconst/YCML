//
//  YCBinaryRBM.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 2/3/15.
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

- (Matrix *)gibbsStep:(Matrix *)visible
{
    return [self sampleVisibleGivenHidden:[self sampleHiddenGivenVisible:visible]];
}

- (Matrix *)freeEnergy:(Matrix *)visible
{
    // visible: NxS
    Matrix *wxb = [self prePropagateToHidden:visible]; // HxN * NxS = HxS (wxb)
    [wxb applyFunction:^double(double value) { return log(1 + exp(value)); }];
    Matrix *ht = [wxb sumsOfColumns]; // 1xS (hidden)
    
    Matrix *av = [self.visibleBiases matrixByTransposingAndMultiplyingWithRight:visible]; // (Nx1)T * NxS = 1xS (vBias)
    
    [av add:ht]; // hidden + vis
    [av negate]; // - hidden - vis
    return av; // 1xS
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
