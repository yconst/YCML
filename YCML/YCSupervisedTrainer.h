//
//  YCSupervisedTrainer.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 2/3/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
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

@import Foundation;
@class YCSupervisedModel, YCMatrix;

@interface YCSupervisedTrainer : NSObject <NSCopying, NSCoding>

/**
 Allocates and initializes a new instance of the receiving class.
 
 @return The new instance
 */
+ (instancetype)trainer;

/**
 Returns the model class associated with the receiver. This method
 should be implemented when subclassing.
 
 @return The model class associated with the receiver
 */
+ (Class)modelClass;

/**
 Trains and returns the supplied model, using input and output matrices.
 
 @param model  The model to train
 @param input  The training input
 @param output The training output
 
 @return The trained model (if input != nil, it is the same as the input)
 */
- (YCSupervisedModel *)train:(YCSupervisedModel *)model
                 inputMatrix:(YCMatrix *)input
                outputMatrix:(YCMatrix *)output;

/**
 Actually performs the training routine. This method should be implemented
 when subclassing
 
 @param model  The model to train
 @param input  The training input
 @param output The training output
 */
- (void)performTrainingModel:(YCSupervisedModel *)model
                 inputMatrix:(YCMatrix *)input
                outputMatrix:(YCMatrix *)output;

/**
 Sends a request to the receiver to stop any ongoing processing.
 */
- (void)stop;

/**
 Holds whether the receiver is bound to stop.
 */
@property (readonly) BOOL shouldStop;

/**
 Holds training algorithm settings
 */
@property NSMutableDictionary *settings;

@end
