//
//  YCFFN+IO.m
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

#import "YCFFN+IO.h"

@implementation YCFFN (IO)

#pragma mark - NSCopying Implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCFFN *copy = [super copyWithZone:zone];
    if (copy)
    {
        copy.layers = [self.layers copy];
        copy.inputTransform = [self.inputTransform copy];
        copy.outputTransform = [self.outputTransform copy];
    }
    return copy;
}

#pragma mark - NSCoding Implementation

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.layers forKey:@"layers"];
    [aCoder encodeObject:self.inputTransform forKey:@"inputTransform"];
    [aCoder encodeObject:self.outputTransform forKey:@"outputTransform"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.layers = [aDecoder decodeObjectForKey:@"layers"];
        self.inputTransform = [aDecoder decodeObjectForKey:@"inputTransform"];
        self.outputTransform = [aDecoder decodeObjectForKey:@"outputTransform"];
    }
    return self;
}

#pragma mark - Text Description

- (NSString *)textDescription
{
    NSMutableString *description = (NSMutableString *)[super textDescription];
    [description appendFormat:@"\nActivation function is Sigmoid\n"];
    
    // Print input and output transform matrices
    if (self.inputTransform)
    {
        [description appendFormat:@"\nInput Transform (%d x %d)\nMapping Function: y = c1*x + c2\n%@",self.inputTransform.rows,
         self.inputTransform.columns, self.inputTransform];
    }
    if (self.outputTransform)
    {
        [description appendFormat:@"\nOutput Transform (%d x %d)\nMapping Function: y = c1*x + c2\n%@",self.outputTransform.rows,
         self.outputTransform.columns, self.outputTransform];
    }
    
    [description appendFormat:@"\nLayers\n"];
    
    NSUInteger currentLayer = 0;
    for (YCModelLayer *layer in self.layers)
    {
        [description appendString:[layer textDescriptionWithModel:self layerIndex:currentLayer++]];
    }
    return description;
}

#pragma mark - PMML Export
#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))

- (void)PMMLEncodeWithRootElement:(NSXMLElement *)root
{
    [super PMMLEncodeWithRootElement:root];
    
    NSXMLElement *network = [[NSXMLElement alloc] initWithName:@"NeuralNetwork"];
    [network addAttribute:[NSXMLNode attributeWithName:@"functionName"
                                           stringValue:@"regression"]];
    [network addAttribute:[NSXMLNode attributeWithName:@"numberOfLayers"
                                           stringValue:[NSString stringWithFormat:@"%lu",
                                                        self.layers.count]]];
    
    // TODO: Add local transformation
    
    NSXMLElement *neuralInputs = [[NSXMLElement alloc] initWithName:@"NeuralInputs"];
    [neuralInputs addAttribute:[NSXMLNode attributeWithName:@"numberOfInputs"
                                                stringValue:[NSString stringWithFormat:@"%d",
                                                             self.inputSize]]];
    
    NSArray *inputConversionArray = self.properties[@"InputConversionArray"];
    
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
        
        NSXMLElement *neuralInput = [[NSXMLElement alloc] initWithName:@"NeuralInput"];
        [neuralInput addAttribute:[NSXMLNode attributeWithName:@"id"
                                                   stringValue:[NSString stringWithFormat:
                                                                @"0,%lu", (unsigned long)i]]];
        
        NSXMLElement *derivedField = [[NSXMLElement alloc] initWithName:@"DerivedField"];
        [derivedField addAttribute:[NSXMLNode attributeWithName:@"dataType"
                                                    stringValue:@"double"]];
        [derivedField addAttribute:[NSXMLNode attributeWithName:@"optype"
                                                    stringValue:@"continuous"]];
        
        NSXMLElement *fieldRef = [[NSXMLElement alloc] initWithName:@"FieldRef"];
        [fieldRef addAttribute:[NSXMLNode attributeWithName:@"field"
                                                stringValue:attributeName]];
        
        [derivedField addChild:fieldRef];
        [neuralInput addChild:derivedField];
        [neuralInputs addChild:neuralInput];
    }
    
    [network addChild:neuralInputs];
    
    NSUInteger currentLayer = 1;
    for (YCFullyConnectedLayer *layer in self.layers)
    {
        [layer PMMLEncodeWithTargetElement:network model:self layerIndex:currentLayer++];
    }
    
    NSXMLElement *neuralOutputs = [[NSXMLElement alloc] initWithName:@"NeuralOutputs"];
    [neuralInputs addAttribute:[NSXMLNode attributeWithName:@"numberOfOutputs"
                                                stringValue:[NSString stringWithFormat:@"%d",
                                                             self.outputSize]]];
    
    NSArray *outputConversionArray = self.properties[@"OutputConversionArray"];
    
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
        
        NSXMLElement *neuralOutput = [[NSXMLElement alloc] initWithName:@"NeuralOutput"];
        NSString *neuronID = [NSString stringWithFormat:@"%lu,%lu",
                              self.layers.count,(unsigned long)i];
        [neuralOutput addAttribute:[NSXMLNode attributeWithName:@"id"
                                                    stringValue:neuronID]];
        
        NSXMLElement *derivedField = [[NSXMLElement alloc] initWithName:@"DerivedField"];
        [derivedField addAttribute:[NSXMLNode attributeWithName:@"dataType"
                                                    stringValue:@"double"]];
        [derivedField addAttribute:[NSXMLNode attributeWithName:@"optype"
                                                    stringValue:@"continuous"]];
        
        NSXMLElement *fieldRef = [[NSXMLElement alloc] initWithName:@"FieldRef"];
        [fieldRef addAttribute:[NSXMLNode attributeWithName:@"field"
                                                stringValue:attributeName]];
        
        [derivedField addChild:fieldRef];
        [neuralOutput addChild:derivedField];
        [neuralOutputs addChild:neuralOutput];
    }
    
    [network addChild:neuralOutputs];
    
    [root addChild:network];
}
#endif

@end
