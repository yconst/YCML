//
//  YCProblem.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 19/3/15.
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

#import "YCOptimizer.h"

@implementation YCOptimizer

- (instancetype)init
{
    return [self initWithProblem:nil];
}

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem
{
    return [self initWithProblem:aProblem settings:nil];
}

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem settings:(NSDictionary *)settings
{
    self = [super init];
    if (self)
    {
        self.state                              = [NSMutableDictionary dictionary];
        self.settings                           = [NSMutableDictionary dictionary];
        self.settings[@"Iterations"]            = @20;
        self.settings[@"Notification Interval"] = @20;
        if (settings) [self.settings addEntriesFromDictionary:settings];
        self.problem                            = aProblem;
    }
    return self;
}

- (void)run
{
    self.shouldStop = NO;
    
    int notificationInterval = [self.settings[@"Notification Interval"] intValue];
    int currentIteration     = [self.state[@"currentIteration"] intValue] + 1;
    int endIteration         = [self.settings[@"Iterations"] intValue] + currentIteration;
    BOOL hasDelegate = self.delegate && [self.delegate respondsToSelector:@selector(stepComplete:)];
    
    for (; currentIteration<endIteration; currentIteration++)
    {
        @autoreleasepool
        {
            BOOL shouldContinue = [self iterate:currentIteration];
            self.state[@"currentIteration"] = @(currentIteration);
            if (hasDelegate && notificationInterval > 0 &&
                currentIteration % notificationInterval == 0)
            {
                [self.delegate stepComplete:self.state];
            }
            if (!shouldContinue || self.shouldStop) break;
        }
    }
}

// Implement in Subclass
- (BOOL)iterate:(int)iteration
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

// Optionally implement in Subclass
- (void)reset
{
    self.state      = [NSMutableDictionary dictionary];
    self.statistics = [NSMutableDictionary dictionary];
}

- (void)stop
{
    self.shouldStop = YES;
}

- (NSArray *)bestParameters
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

- (NSArray *)bestObjectives
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

- (NSArray *)bestConstraints
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

#pragma mark NSCopying implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCOptimizer *opt = [[[self class] alloc] initWithProblem:self.problem];
    if (opt)
    {
        opt.state      = [self.state mutableCopy];
        opt.settings   = [self.settings mutableCopy];
        opt.statistics = [self.statistics mutableCopy];
    }
    return opt;
}

#pragma mark NSCoding Implementation

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.settings   = [aDecoder decodeObjectForKey:@"settings"];
        self.state      = [aDecoder decodeObjectForKey:@"state"];
        self.statistics = [aDecoder decodeObjectForKey:@"statistics"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.settings forKey:@"settings"];
    [aCoder encodeObject:self.state forKey:@"state"];
    [aCoder encodeObject:self.statistics forKey:@"statistics"];
}

@end
