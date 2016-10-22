//
//  YCGenericTrainer.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 2/3/15.
//  Copyright (c) 2015 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
//
// This file is part of YCML.
//
// YCML is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// YCML is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with YCML.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>

@protocol YCTrainerDelegate <NSObject>

- (void)stepComplete:(NSDictionary *)info;

@end

@interface YCGenericTrainer : NSObject

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

@property NSObject<YCTrainerDelegate> *delegate;

@end
