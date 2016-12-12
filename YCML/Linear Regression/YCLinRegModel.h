//
//  YCLinRegModel.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 12/12/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import <YCML/YCML.h>
@class Matrix;

@interface YCLinRegModel : YCSupervisedModel

@property (strong) Matrix *theta;

@property (strong) Matrix *inputTransform;

@property (strong) Matrix *outputTransform;

@end
