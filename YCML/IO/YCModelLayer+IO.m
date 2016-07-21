//
//  YCModelLayer+IO.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 20/4/16.
//  Copyright © 2016 (Yannis) Chatzikonstantinou. All rights reserved.
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

#import "YCModelLayer+IO.h"

@implementation YCModelLayer (IO)

#pragma mark - NSCoding Implementation

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.properties = [aDecoder decodeObjectForKey:@"properties"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.properties forKey:@"properties"];
}

#pragma mark - NSCopying Implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCModelLayer *layer = [[[self class] alloc] init];
    layer.properties = [self.properties copy];
    return layer;
}

#pragma mark - Text Description

- (NSString *)textDescriptionWithLayerIndex:(NSUInteger)index
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

#pragma mark - PMML Export
#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))

- (void)PMMLEncodeWithTargetElement:(NSXMLElement *)target
                              model:(YCFFN *)model
                         layerIndex:(NSUInteger)index
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}
#endif

@end
