//
//  YCSupervisedModel+IO.m
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

#import "YCSupervisedModel+IO.h"

@implementation YCSupervisedModel (IO)

#pragma mark - Text Description

- (NSString *)textDescription
{
    NSMutableString *description = (NSMutableString *)[super textDescription];
    
    // Print input conversion array
    if (self.properties[@"InputConversionArray"])
    {
        [description appendFormat:@"\nInput Conversion Array\n\n"];
        [self.properties[@"InputConversionArray"] enumerateObjectsUsingBlock:^(id  __nonnull obj,
                                                                               NSUInteger idx,
                                                                               BOOL * __nonnull stop) {
            NSString *string = obj;
            [description appendFormat:@"\t%@", string];
        }];
    }
    
    // Print output conversion array
    [description appendFormat:@"\n"];
    if (self.properties[@"OutputConversionArray"])
    {
        [description appendFormat:@"\nOutput Conversion Array\n\n"];
        [self.properties[@"OutputConversionArray"] enumerateObjectsUsingBlock:^(id  __nonnull obj,
                                                                                NSUInteger idx,
                                                                                BOOL * __nonnull stop) {
            NSString *string = obj;
            [description appendFormat:@"\t%@", string];
        }];
    }
    [description appendFormat:@"\n"];
    
    return description;
}

#pragma mark - PMML Export
#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))

- (void)PMMLEncodeWithRootElement:(NSXMLElement *)root
{
    [super PMMLEncodeWithRootElement:root];
    
    NSXMLElement *ddict = [[NSXMLElement alloc] initWithName:@"DataDictionary"];
    [ddict addAttribute:[NSXMLNode attributeWithName:@"numberOfFields"
                                         stringValue:[NSString stringWithFormat:@"%d",
                                                      self.inputSize + self.outputSize]]];
    
    NSArray *inputConversionArray = self.properties[@"InputConversionArray"];
    NSDictionary *inputMinValues = self.properties[@"InputMinValues"];
    NSDictionary *inputMaxValues = self.properties[@"InputMaxValues"];
    
    for (NSUInteger i=0; i<self.inputSize; i++)
    {
        NSString *attributeName;
        if (inputConversionArray && inputConversionArray.count > i)
        {
            attributeName = inputConversionArray[i];
        }
        else
        {
            attributeName = [NSString stringWithFormat:@"Input %lu", (unsigned long)i];
        }
        
        NSXMLElement *attribute = [[NSXMLElement alloc] initWithName:@"DataField"];
        [attribute addAttribute:[NSXMLNode attributeWithName:@"dataType"
                                                 stringValue:@"double"]];
        [attribute addAttribute:[NSXMLNode attributeWithName:@"name"
                                                 stringValue:attributeName]];
        [attribute addAttribute:[NSXMLNode attributeWithName:@"optype"
                                                 stringValue:@"continuous"]];
        
        id iminValue = inputMinValues[attributeName];
        id imaxValue = inputMaxValues[attributeName];
        if (iminValue && imaxValue)
        {
            NSXMLElement *interval = [[NSXMLElement alloc] initWithName:@"Interval"];
            [interval addAttribute:[NSXMLNode attributeWithName:@"closure"
                                                    stringValue:@"closedClosed"]];
            [interval addAttribute:[NSXMLNode attributeWithName:@"leftMargin"
                                                    stringValue:[iminValue stringValue]]];
            [interval addAttribute:[NSXMLNode attributeWithName:@"rightMargin"
                                                    stringValue:[imaxValue stringValue]]];
            [attribute addChild:interval];
        }
        
        [ddict addChild:attribute];
    }
    
    NSArray *outputConversionArray = self.properties[@"OutputConversionArray"];
    NSDictionary *outputMinValues = self.properties[@"OutputMinValues"];
    NSDictionary *outputMaxValues = self.properties[@"OutputMaxValues"];
    
    for (NSUInteger i=0; i<self.outputSize; i++)
    {
        NSString *attributeName;
        if (outputConversionArray && outputConversionArray.count > i)
        {
            attributeName = outputConversionArray[i];
        }
        else
        {
            attributeName = [NSString stringWithFormat:@"Output %lu", (unsigned long)i];
        }
        
        NSXMLElement *attribute = [[NSXMLElement alloc] initWithName:@"DataField"];
        [attribute addAttribute:[NSXMLNode attributeWithName:@"dataType"
                                                 stringValue:@"double"]];
        [attribute addAttribute:[NSXMLNode attributeWithName:@"name"
                                                 stringValue:attributeName]];
        [attribute addAttribute:[NSXMLNode attributeWithName:@"optype"
                                                 stringValue:@"continuous"]];
        
        id ominValue = outputMinValues[attributeName];
        id omaxValue = outputMaxValues[attributeName];
        if (ominValue && omaxValue)
        {
            NSXMLElement *interval = [[NSXMLElement alloc] initWithName:@"Interval"];
            [interval addAttribute:[NSXMLNode attributeWithName:@"closure"
                                                    stringValue:@"closedClosed"]];
            [interval addAttribute:[NSXMLNode attributeWithName:@"leftMargin"
                                                    stringValue:[ominValue stringValue]]];
            [interval addAttribute:[NSXMLNode attributeWithName:@"rightMargin"
                                                    stringValue:[omaxValue stringValue]]];
            [attribute addChild:interval];
        }
        
        [ddict addChild:attribute];
    }
    [root addChild:ddict];
}
#endif

@end
