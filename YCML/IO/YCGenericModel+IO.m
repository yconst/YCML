//
//  YCGenericModel+IO.m
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

#import "YCGenericModel+IO.h"

@implementation YCGenericModel (IO)

+ (YCGenericModel *)modelWithPMMLString:(NSString *)string
{
    @throw [NSInternalInconsistencyException initWithFormat:@"Not yet implemented"];
}

#pragma mark - NSCopying Implementation

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

#pragma mark - NSCoding Implementation

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

#pragma mark - Text Description

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

#pragma mark - PMML Export
#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))

- (void)PMMLEncodeWithRootElement:(NSXMLElement *)root
{
    NSXMLElement *header = [[NSXMLElement alloc] initWithName:@"Header"];
    [header addAttribute:[NSXMLNode attributeWithName:@"Copyright" stringValue:@"User"]];
    [header addAttribute:[NSXMLNode attributeWithName:@"Timestamp"
                                          stringValue:[NSString stringWithFormat:@"%@", [NSDate date]]]];
    
    NSXMLElement *application = [[NSXMLElement alloc] initWithName:@"Application"];
    [application addAttribute:[NSXMLNode attributeWithName:@"Name" stringValue:@"YCML"]];
    
    [header addChild:application];
    
    [root addChild:header];
}

- (NSString *)PMMLString
{
    NSXMLElement *root = [[NSXMLElement alloc] initWithName:@"PMML"];
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
    [xmlDoc setVersion:@"1.0"];
    [xmlDoc setCharacterEncoding:@"UTF-8"];
    
    [self PMMLEncodeWithRootElement:root];
    
    NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
    
    return [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
}
#endif

@end
