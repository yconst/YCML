//
//  YCSurrogateModel.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 5/7/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
//

@import Foundation;
#import "YCProblem.h"
#import "YCSupervisedModel.h"

@interface YCSurrogateModel : NSObject<YCProblem>

@property YCSupervisedModel *model;

@end
