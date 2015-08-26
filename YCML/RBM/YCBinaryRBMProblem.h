//
//  YCBinaryRBMProblem.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 30/7/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

@import Foundation;
#import "YCDerivativeProblem.h"
@class YCBinaryRBM, Matrix;

@interface YCBinaryRBMProblem : NSObject <YCDerivativeProblem>
{
    Matrix *_inputMatrix;
}

- (instancetype)initWithInputMatrix:(Matrix *)inputMatrix model:(YCBinaryRBM *)model;

- (Matrix *)weightsWithParameters:(Matrix *)parameters;

- (Matrix *)visibleBiasWithParameters:(Matrix *)parameters;

- (Matrix *)hiddenBiasWithParameters:(Matrix *)parameters;

- (void)storeWeights:(Matrix *)weights
       visibleBiases:(Matrix *)vBiases
        hiddenBiases:(Matrix *)hBiases
            toVector:(Matrix *)vector;

@property YCBinaryRBM *trainedModel;

@property double lambda;

@property int sampleCount;

@end
