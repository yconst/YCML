//
//  YCValidation.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 19/10/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCValidation.h"
#import "YCRegressionMetrics.h"
#import "YCSupervisedTrainer.h"

@implementation YCValidation

+ (instancetype)validationWithSettings:(NSDictionary *)settings
{
    return [[self alloc] initWithSettings:settings];
}

- (instancetype)init
{
    return [self initWithSettings:nil evaluator:nil];
}

- (instancetype)initWithSettings:(NSDictionary *)settings
{
    return [self initWithSettings:settings evaluator:nil];
}

- (instancetype)initWithSettings:(NSDictionary *)settings
                       evaluator:(NSDictionary *(^)(YCDataframe *, YCDataframe *,
                                                    YCDataframe *))evaluator
{
    self = [super init];
    if (self)
    {
        self.settings = [NSMutableDictionary dictionary];
        if (settings) [self.settings addEntriesFromDictionary:settings];
        if (evaluator)
        {
            self.evaluator = evaluator;
        }
        else
        {
            self.evaluator = ^NSDictionary *(YCDataframe *ti, YCDataframe *to, YCDataframe *po)
            {
                return @{@"RMSE" : @(sqrt(MSE(to, po))),
                         @"RSquared" : @(RSquared(to, po))};
            };
        }
    }
    return self;
}

- (NSDictionary *)test:(YCSupervisedTrainer *)trainer
                 input:(YCDataframe *)trainingInput
                output:(YCDataframe *)trainingOutput
{
    _activeTrainer = trainer;
    trainer.delegate = self;
    id results = [self performTest:trainer input:trainingInput output:trainingOutput];
    _activeTrainer = nil;
    return results;
}

- (NSDictionary *)performTest:(YCSupervisedTrainer *)trainer
                        input:(YCDataframe *)trainingInput
                       output:(YCDataframe *)trainingOutput
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

- (void)stepComplete:(NSDictionary *)info
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

@end
