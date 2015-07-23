//
//  NSIndexSet+Sampling.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 1/7/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (Sampling)

+ (instancetype)indexesForSampling:(int)samples inRange:(NSRange)range replacement:(BOOL)replacement;

@end
