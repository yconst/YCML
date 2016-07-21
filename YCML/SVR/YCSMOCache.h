//
//  YCSMOCache.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 29/1/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

@import Foundation;
#import "YCLinkedList.h"
@class Matrix;

typedef enum cacheStatus { notReserved, reserved, included } cacheStatus;

@interface YCSMOCache : NSObject

- (instancetype)initWithSize:(NSUInteger)size;

- (cacheStatus)queryI:(int)i j:(int)j;

- (double)getI:(int)i j:(int)j tickle:(BOOL)tickle;

- (double)setI:(int)i j:(int)j value:(double)value;

///@name Properties

@property Matrix *index;

@property Matrix *inverseIndex;

@property Matrix *values;

@property Matrix *status;

@property LNode *nodes;

@property YCLinkedList *order;

@end
