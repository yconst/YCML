//
//  YCBinaryRBM.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 30/7/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

@import Foundation;
@import YCMatrix;
#import "YCGenericModel.h"

@interface YCBinaryRBM : YCGenericModel

- (Matrix *)prePropagateToHidden:(Matrix *)visible;

- (Matrix *)prePropagateToVisible:(Matrix *)hidden;

- (Matrix *)propagateToHidden:(Matrix *)visible;

- (Matrix *)propagateToVisible:(Matrix *)hidden;

- (Matrix *)sampleHiddenGivenVisible:(Matrix *)visible;

- (Matrix *)sampleVisibleGivenHidden:(Matrix *)hidden;

- (Matrix *)freeEnergy:(Matrix *)visible;

@property Matrix *weights;

@property Matrix *visibleBiases;

@property Matrix *hiddenBiases;

@property (readonly) int visibleSize;

@property (readonly) int hiddenSize;

@end
