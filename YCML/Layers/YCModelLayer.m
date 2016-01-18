//
//  YCModelLayer.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 11/10/15.
//  Copyright © 2015 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

#import "YCModelLayer.h"

@implementation YCModelLayer

+ (instancetype)layer
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.properties = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.properties = [aDecoder decodeObjectForKey:@"properties"];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCModelLayer *layer = [[[self class] alloc] init];
    layer.properties = [self.properties copy];
    return layer;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.properties forKey:@"properties"];
}

@end
