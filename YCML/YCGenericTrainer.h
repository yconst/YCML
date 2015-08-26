//
//  YCGenericTrainer.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 18/8/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCGenericTrainer : NSObject <NSCopying, NSCoding>

/**
 Allocates and initializes a new instance of the receiving class.
 
 @return The new instance
 */
+ (instancetype)trainer;

/**
 Returns the model class associated with the receiver. This method
 should be implemented when subclassing.
 
 @return The model class associated with the receiver.
 */
+ (Class)modelClass;

/**
 Sends a request to the receiver to stop any ongoing processing.
 */
- (void)stop;

/**
 Holds whether the receiver is bound to stop.
 */
@property BOOL shouldStop;

/**
 Holds training algorithm settings.
 */
@property NSMutableDictionary *settings;

@end
