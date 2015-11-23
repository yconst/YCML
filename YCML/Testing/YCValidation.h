//
//  YCValidation.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 19/10/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

@import Foundation;
@class YCSupervisedTrainer, YCDataframe;

@interface YCValidation : NSObject

+ (instancetype)validationWithSettings:(NSDictionary *)settings;

- (instancetype)initWithSettings:(NSDictionary *)settings;

- (instancetype)initWithSettings:(NSDictionary *)settings
                       evaluator:(NSDictionary *(^)(YCDataframe *, YCDataframe *,
                                                    YCDataframe *))evaluator;

- (NSDictionary *)test:(YCSupervisedTrainer *)trainer
                 input:(YCDataframe *)trainingInput
                output:(YCDataframe *)trainingOutput;

- (NSDictionary *)performTest:(YCSupervisedTrainer *)trainer
                        input:(YCDataframe *)trainingInput
                       output:(YCDataframe *)trainingOutput;

@property (copy) NSDictionary *(^evaluator)(YCDataframe *, YCDataframe *,
YCDataframe *);

@property NSMutableDictionary *settings;

@property NSDictionary *results;

@property NSArray *models;

@property YCSupervisedTrainer *activeTrainer;

@end
