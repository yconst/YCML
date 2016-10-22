//
//  YCProblem.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 19/3/15.
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
//

@import Foundation;
#import "YCProblem.h"

@protocol YCOptimizerDelegate <NSObject>

- (void)stepComplete:(NSDictionary *)info;

@end

@interface YCOptimizer : NSObject <NSCopying, NSCoding>

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem;

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem settings:(NSDictionary *)settings;

- (void)run;

- (BOOL)iterate:(int)iteration;

/**
 Resets the receiver's state. Settings are kept.
 */
- (void)reset;

/**
 Sends a request to the receiver to stop any ongoing processing.
 */
- (void)stop;

/**
 Holds whether the receiver is bound to stop.
 */
@property BOOL shouldStop;

@property NSObject<YCProblem> *problem;

@property NSMutableDictionary *state;

@property NSMutableDictionary *settings;

@property NSMutableDictionary *statistics;

@property (readonly) NSArray *bestParameters;

@property (readonly) NSArray *bestObjectives;

@property (readonly) NSArray *bestConstraints;

@property NSObject<YCOptimizerDelegate> *delegate;

@end
