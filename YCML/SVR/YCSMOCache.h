//
//  YCSMOCache.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 29/1/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum cacheStatus { notInCache, allocated, present } cacheStatus;

@interface YCSMOCache : NSObject

- (instancetype)initWithSize:(int)size;

- (cacheStatus)queryI:(int)i j:(int)j;

- (void)pingI:(int)i j:(int)j;

- (double)getI:(int)i j:(int)j;

- (double)setI:(int)i j:(int)j value:(double)value;

@end
