//
//  YCFullyConnectedLayer+IO.m
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

#import "YCFullyConnectedLayer+IO.h"

@implementation YCFullyConnectedLayer (IO)

#pragma mark - NSCoding Implementation

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.weightMatrix = [aDecoder decodeObjectForKey:@"weightMatrix"];
        self.biasVector = [aDecoder decodeObjectForKey:@"biasVector"];
        self.lastActivation = [aDecoder decodeObjectForKey:@"lastActivation"];
        self.L2 = [aDecoder decodeDoubleForKey:@"L2"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.weightMatrix forKey:@"weightMatrix"];
    [aCoder encodeObject:self.biasVector forKey:@"biasVector"];
    [aCoder encodeObject:self.lastActivation forKey:@"lastActivation"];
    [aCoder encodeDouble:self.L2 forKey:@"L2"];
}

#pragma mark - NSCopying Implementation

- (id)copyWithZone:(NSZone *)zone
{
    YCFullyConnectedLayer *copy = [super copyWithZone:zone];
    copy.weightMatrix = [self.weightMatrix copy];
    copy.biasVector = [self.biasVector copy];
    copy.L2 = self.L2;
    copy.lastActivation = [self.lastActivation copy];
    return copy;
}

#pragma mark - Text Description

- (NSString *)textDescriptionWithModel:(YCFFN *)model layerIndex:(NSUInteger)index
{
    NSMutableString *description = [NSMutableString string];
    if (model.hiddenLayerCount == 0)
    {
        [description appendFormat:@"\nInput to Output Weights (%d x %d)\n%@",self.inputSize,
         self.outputSize, self.weightMatrix];
        
        [description appendFormat:@"\nInput to Output Biases (%d x 1)\n%@",self.outputSize, self.biasVector];
    }
    else if (index == 0)
    {
        // Print input-hidden layer weights
        [description appendFormat:@"\nInput to H1 Weights (%d x %d)\n%@",self.inputSize,
         self.outputSize, self.weightMatrix];
        
        [description appendFormat:@"\nInput to H1 Biases (%d x 1)\n%@",self.outputSize, self.biasVector];
    }
    else if (index == model.hiddenLayerCount)
    {
        // Print hidden-output layer weights
        [description appendFormat:@"\nH%lu to Output Weights (%d x %d)\n%@",index,
         self.inputSize, self.outputSize, self.weightMatrix];
        
        [description appendFormat:@"\nH%lu to Output Biases (%d x 1)\n%@",index,
         self.outputSize, self.biasVector];
    }
    else
    {
        // Print hidden-hidden layer weights
        [description appendFormat:@"\nH%lu to H%lu Weights (%d x %d)\n%@",index,
         index + 1, self.inputSize, self.outputSize, self.weightMatrix];
        
        [description appendFormat:@"\nH%lu to H%lu Biases (%d x 1)\n%@",index,
         index + 1, self.outputSize, self.biasVector];
    }
    return description;
}

#pragma mark - PMML Export
#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))

- (void)PMMLEncodeWithTargetElement:(NSXMLElement *)target
                              model:(YCFFN *)model
                         layerIndex:(NSUInteger)index
{
    NSXMLElement *neuralLayer = [[NSXMLElement alloc] initWithName:@"NeuralLayer"];
    for (NSUInteger i = 0; i<self.outputSize; i++)
    {
        NSXMLElement *neuron = [[NSXMLElement alloc] initWithName:@"Neuron"];
        
        NSString *nID = [NSString stringWithFormat:@"%lu,%lu", index, i];
        [neuron addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:nID]];
        
        NSString *nBias = [NSString stringWithFormat:@"%f", [self.biasVector i:(int)i j:0]];
        [neuron addAttribute:[NSXMLNode attributeWithName:@"bias" stringValue:nBias]];
        
        for (NSUInteger j = 0; j<self.inputSize; j++)
        {
            NSXMLElement *con = [[NSXMLElement alloc] initWithName:@"Con"];
            
            NSString *cFrom = [NSString stringWithFormat:@"%lu,%lu", index-1, j];
            [con addAttribute:[NSXMLNode attributeWithName:@"from" stringValue:cFrom]];
            
            NSString *cWeight = [NSString stringWithFormat:@"%f", [self.weightMatrix i:(int)j
                                                                                      j:(int)i]];
            [con addAttribute:[NSXMLNode attributeWithName:@"weight" stringValue:cWeight]];
            
            [neuron addChild:con];
        }
        
        [neuralLayer addChild:neuron];
    }
    [target addChild:neuralLayer];
}
#endif

@end
