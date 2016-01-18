//
//  YCModelKernel.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 11/1/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCModelKernel.h"

@implementation YCModelKernel

+ (instancetype)kernel
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

- (Matrix *)kernelValueForA:(Matrix *)a b:(Matrix *)b
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

@end
