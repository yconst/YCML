//
//  YCGenericModel.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 18/8/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCGenericModel : NSObject <NSCopying, NSCoding>

/**
 Allocates and initializes a new instance of the receiver class.
 
 @return The new instance.
 */
+ (instancetype)model;

/**
 Holds statistics about the model, usually related to the learning process.
 */
@property NSMutableDictionary *statistics;

/**
 Holds model properties.
 */
@property NSMutableDictionary *properties;

/**
 Holds training settings used to train this model.
 */
@property NSMutableDictionary *trainingSettings;

@end
