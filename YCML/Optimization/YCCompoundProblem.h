//
//  YCCompoundProblem.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 23/7/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YCProblem.h"

@interface YCCompoundProblem : NSObject <YCProblem>

@property NSMutableArray *problems;

@end
