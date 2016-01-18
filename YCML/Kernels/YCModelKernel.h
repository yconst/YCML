//
//  YCModelKernel.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 11/1/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

@import Foundation;
@class Matrix;

@interface YCModelKernel : NSObject

+ (instancetype)kernel;

- (Matrix *)kernelValueForA:(Matrix *)a b:(Matrix *)b;

/**
 Holds kernel properties.
 */
@property NSMutableDictionary *properties;

@end
