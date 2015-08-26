//
//  YCGenericTrainer.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 18/8/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCGenericTrainer.h"

@implementation YCGenericTrainer

+ (instancetype)trainer
{
    return [[self alloc] init];
}

+ (Class)modelClass
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

-(id)init
{
    if (self = [super init])
    {
        self.settings = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.settings forKey:@"settings"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        self.settings = [decoder decodeObjectForKey:@"settings"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copied = [[self class] trainer];
    if (copied)
    {
        [copied setSettings:[self.settings mutableCopy]];
    }
    return copied;
}

- (void)stop
{
    self->_shouldStop = true;
}

@end
