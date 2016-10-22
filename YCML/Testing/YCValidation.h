//
//  YCValidation.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 19/10/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

@import Foundation;
#import "YCGenericTrainer.h"
@class YCSupervisedTrainer, YCDataframe;

@protocol YCValidationDelegate <NSObject>

- (void)stepComplete:(NSDictionary *)info;

@end

@interface YCValidation : NSObject <YCTrainerDelegate>

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

@property NSObject<YCValidationDelegate> *delegate;

@end
