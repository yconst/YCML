//
//  YCGenericModel.m
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

#import "YCGenericModel.h"

@implementation YCGenericModel

+ (instancetype)model
{
    return [[self alloc] init];
}

#pragma mark Initialization

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.statistics       = [NSMutableDictionary dictionary];
        self.properties       = [NSMutableDictionary dictionary];
        self.trainingSettings = [NSMutableDictionary dictionary];
    }
    return self;
}

@end
