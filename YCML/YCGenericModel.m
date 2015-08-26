//
//  YCGenericModel.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 18/8/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCGenericModel.h"

@implementation YCGenericModel

+ (instancetype)model
{
    return [[self alloc] init];
}

#pragma mark NSCopying Implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    id copied = [[self class] model];
    if (copied)
    {
        [copied setProperties:[self.properties mutableCopy]];
        [copied setStatistics:[self.statistics mutableCopy]];
        [copied setTrainingSettings:[self.trainingSettings mutableCopy]];
    }
    return copied;
}

#pragma mark NSCoding Implementation

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.properties forKey:@"properties"];
    [encoder encodeObject:self.statistics forKey:@"statistics"];
    [encoder encodeObject:self.trainingSettings forKey:@"trainingSettings"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        self.properties = [decoder decodeObjectForKey:@"properties"];
        self.statistics = [decoder decodeObjectForKey:@"statistics"];
        self.trainingSettings = [decoder decodeObjectForKey:@"trainingSettings"];
    }
    return self;
}

@end
