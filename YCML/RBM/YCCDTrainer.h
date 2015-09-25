//
//  YCBinaryRBMTrainer.h
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
#import "YCGenericTrainer.h"
@class YCBinaryRBM, YCDataframe, Matrix;

@interface YCCDTrainer : YCGenericTrainer

+ (Class)optimizerClass;

/**
 Trains a model using the receiver's training algorithm and a (binary) input.
 
 @param model  The model to train. Can be nil.
 @param input  The training input.
 
 @return The trained model (if input != nil, it is the same as the input)
 */
- (YCBinaryRBM *)train:(YCBinaryRBM *)model input:(YCDataframe *)input;

/**
 Trains a model using the receiver's training algorithm, and a (binary) matrix as input.
 
 @param model  The model to train. Can be nil.
 @param input  The training input.
 
 @return The trained model (if input != nil, it is the same as the input)
 */
- (YCBinaryRBM *)train:(YCBinaryRBM *)model inputMatrix:(Matrix *)input;

/**
 Implements the actual training routine. This method should be implemented
 when subclassing.
 
 @param model  The model to train.
 @param input  The training input.
 */
- (void)performTrainingModel:(YCBinaryRBM *)model inputMatrix:(Matrix *)input;

@end
