//
//  YCBinaryRBMTrainer.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 30/7/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YCGenericTrainer.h"
@class YCBinaryRBM, YCDataframe, Matrix;

@interface YCBinaryRBMTrainer : YCGenericTrainer

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
