//
//  HaltonInterface.h
//  YCMatrix
//
//  Created by Ioannis Chatzikonstantinou on 21/12/15.
//  Copyright © 2015 Ioannis Chatzikonstantinou. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Matrix;

@interface HaltonInterface : NSObject

+ (Matrix *)sampleWithDimension:(int)dimension count:(int)count;

@end
