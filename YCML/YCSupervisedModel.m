//
//  YCSupervisedModel.m
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

#import "YCSupervisedModel.h"
#import "YCMatrix/YCMatrix.h"

@implementation YCSupervisedModel

@synthesize settings, statistics;

+ (instancetype)model
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.statistics = [NSMutableDictionary dictionary];
        self.settings = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark Learner Implementation

- (YCMatrix *)activateWithMatrix:(YCMatrix *)matrix
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

#pragma mark NSCoding Implementation

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.settings forKey:@"settings"];
    [encoder encodeObject:self.statistics forKey:@"statistics"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        self.settings = [decoder decodeObjectForKey:@"settings"];
        self.statistics = [decoder decodeObjectForKey:@"statistics"];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    id copied = [YCSupervisedModel model];
    if (copied)
    {
        [copied setSettings:[self.settings mutableCopy]];
        [copied setStatistics:[self.statistics mutableCopy]];
    }
    return copied;
}

@end

