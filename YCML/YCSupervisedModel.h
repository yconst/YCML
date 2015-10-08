//
//  YCSupervisedModel.h
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

@import Foundation;
#import "YCGenericModel.h"
@class Matrix, YCDataframe;

/**
 The base class for all supervised predictive models. Extends the base model
 class with methods for activating the receiver using either datasets or matrices,
 as well as properties for determining the input and output size of the receiver.
 */
@interface YCSupervisedModel : YCGenericModel

/**
 Activates the receiver using the passed dataframe.
 
 @param input The dataframe used as input for activation.
 
 @return The output dataframe resulting from the prediction.
 */
- (YCDataframe *)activateWithDataframe:(YCDataframe *)input;

/**
 Activates the receiver using the passed matrix.
 
 @param matrix The matrix to use as input for the activation.
 
 @return The output matrix resulting from the prediction.
 */
- (Matrix *)activateWithMatrix:(Matrix *)matrix;

/**
 Returns the receiver's input size.
 */
@property (readonly) int inputSize;

/**
 Returns the receiver's output size.
 */
@property (readonly) int outputSize;

@end
