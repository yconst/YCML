//
//  YCLinearModelProblem.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 12/12/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YCDerivativeProblem.h"
@class Matrix, YCLinRegModel;

@interface YCLinearModelProblem : NSObject <YCDerivativeProblem>

- (instancetype)initWithInputMatrix:(Matrix *)input
                       outputMatrix:(Matrix *)output
                              model:(YCLinRegModel *)model;

- (Matrix *)thetaWithParameters:(Matrix *)parameters;

@property YCLinRegModel *model;

@property double l2;

@end
