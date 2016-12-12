//
//  YCLinearModelProblem.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 12/12/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YCProblem.h"
@class Matrix, YCLinRegModel;

@interface YCLinearModelProblem : NSObject <YCProblem>

- (instancetype)initWithInputMatrix:(Matrix *)input
                       outputMatrix:(Matrix *)output
                              model:(YCLinRegModel *)model;

- (Matrix *)thetaWithParameters:(Matrix *)parameters;

@property YCLinRegModel *model;

@property double lambda;

@end
