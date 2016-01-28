//
//  YCSVR.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 11/12/15.
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

#import "YCSupervisedModel.h"
@class Matrix, YCModelKernel;

@interface YCSVR : YCSupervisedModel

/**
 Returns the kernel instance of this model.
 */
@property YCModelKernel *kernel;

/**
 Returns a matrix corresponding to the support vectors of the receiver.
 */
@property Matrix *sv;

/**
 Returns a vector corresponding to the lambdas of the receiver.
 */
@property Matrix *lambda;

/**
 Returns the bias of the receiver
 */
@property double b;

/**
 Returns the input transformation matrix of the receiver.
 */
@property Matrix *inputTransform;

/**
 Returns the output reverse transformation matrix of the receiver.
 */
@property Matrix *outputTransform;

@end
