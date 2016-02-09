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

- (NSString *)textDescription
{
    NSMutableString *description = [NSMutableString string];
    
    [description appendFormat:@"%@\n\n", self.class];
    
    [description appendFormat:@"Training Settings\n\n"];
    for (NSString *key in self.trainingSettings.allKeys)
    {
        [description appendFormat:@"\t%@ : %@\n", key, self.trainingSettings[key]];
    }
    
    [description appendFormat:@"\nStatistics\n\n"];
    for (NSString *key in self.statistics.allKeys)
    {
        [description appendFormat:@"\t%@ : %@\n", key, self.statistics[key]];
    }
    [description appendFormat:@"\n"];
    
    return description;
}

//- (void)PMMLEncodeWithRootElement:(NSXMLElement *)root
//{
//
//}

//- (NSString *)PMMLString
//{
//    NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"addresses"];
//    [self PMMLEncodeWithRootElement:root];
//    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
//    [xmlDoc setVersion:@"1.0"];
//    [xmlDoc setCharacterEncoding:@"UTF-8"];
//    return [xmlDoc stringValue];
//}

@end
