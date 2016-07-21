//
//  YCMLModelExportTests.m
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

#import <XCTest/XCTest.h>
@import YCML;
#import "XCTestCase+Dataframe.h"

@interface YCMLModelExportTests : XCTestCase

@end

@implementation YCMLModelExportTests

- (void)testFFN_TextExport
{
    YCFullyConnectedLayer *hl = [YCSigmoidLayer layerWithInputSize:13 outputSize:2];
    YCFullyConnectedLayer *ol = [YCSigmoidLayer layerWithInputSize:2 outputSize:1];
    
    YCFFN *model = [[YCFFN alloc] init];
    
    model.layers = @[hl, ol];
    
    YCRpropTrainer *trainer = [YCRpropTrainer trainer];
    
    YCDataframe *input    = [self dataframeWithCSVName:@"housing"];
    YCDataframe *output   = [YCDataframe dataframeWithDictionary:
                             @{@"MedV" : [input allValuesForAttribute:@"MedV"]}];
    [input removeAttributeWithIdentifier:@"MedV"];
    
    model = (YCFFN *)[trainer train:model input:input output:output];
    
    NSString *text = [model textDescription];
    
    NSLog(@"%@", text);
}

#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))
- (void)testFFN_PMMLExport
{
    YCFullyConnectedLayer *hl = [YCSigmoidLayer layerWithInputSize:13 outputSize:2];
    YCFullyConnectedLayer *ol = [YCSigmoidLayer layerWithInputSize:2 outputSize:1];
    
    YCFFN *model = [[YCFFN alloc] init];
    
    model.layers = @[hl, ol];
    
    YCRpropTrainer *trainer = [YCRpropTrainer trainer];
    
    YCDataframe *input    = [self dataframeWithCSVName:@"housing"];
    YCDataframe *output   = [YCDataframe dataframeWithDictionary:
                            @{@"MedV" : [input allValuesForAttribute:@"MedV"]}];
    [input removeAttributeWithIdentifier:@"MedV"];
    
    model = (YCFFN *)[trainer train:model input:input output:output];
    
    NSString *PMML = [model PMMLString];
    
    NSLog(@"%@", PMML);
}
#endif

@end
