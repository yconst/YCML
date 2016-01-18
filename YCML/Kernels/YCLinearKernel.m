//
//  YCLinearKernel.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 11/1/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCLinearKernel.h"
@import YCMatrix;

@implementation YCLinearKernel

- (Matrix *)kernelValueForA:(Matrix *)a b:(Matrix *)b
{
    // a: NxP, b: NxQ -> out: PxQ
    return [a matrixByTransposingAndMultiplyingWithRight:b];
}

@end
