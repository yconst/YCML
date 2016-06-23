//
//  YCMLDataframeTests.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 13/11/15.
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

@interface YCMLDataframeTests : XCTestCase

@end

@implementation YCMLDataframeTests

- (void)testAddAttributeAndExamples
{
    YCDataframe *frame = [YCDataframe dataframe];
    [frame addAttributeWithIdentifier:@"attr1" data:nil];
    [frame addAttributeWithIdentifier:@"attr2" data:nil];
    [frame addAttributeWithIdentifier:@"attr3" data:nil];
    [frame addAttributeWithIdentifier:@"attr4" data:nil];
    
    XCTAssertEqual(frame.dataCount, 0);
    XCTAssertEqual(frame.attributeCount, 4);
    
    [frame addSampleWithData:@{}];
    
    XCTAssertEqual(frame.dataCount, 1);
}

- (void)testExtractAttributes
{
    YCDataframe *frame = [YCDataframe dataframe];
    [frame addAttributeWithIdentifier:@"attr1" data:nil];
    [frame addAttributeWithIdentifier:@"attr2" data:nil];
    [frame addAttributeWithIdentifier:@"attr3" data:nil];
    [frame addAttributeWithIdentifier:@"attr4" data:nil];
    
    NSArray *values = [frame allSampleValues];
    NSArray *referenceValues = @[@"attr1", @"attr2", @"attr3", @"attr4"];
    
    XCTAssertEqualObjects(values[0], referenceValues);
    
    NSDictionary *example = @{@"attr1" : @3, @"attr2" : @2, @"attr3" : @1, @"attr4" : @0};
    [frame addSampleWithData:example];
    NSArray *examples = [frame allSamples];
    
    XCTAssertEqualObjects(examples[0], example);
}

- (void)testCorruptDataframe
{
    YCDataframe *template = [YCDataframe dataframe];
    [template addSampleWithData:@{@"First" : @0.0, @"Second" : @-1.0, @"Third" : @-5.0}];
    [template addSampleWithData:@{@"First" : @6.7, @"Second" :  @0.1, @"Third" : @40.0}];
    YCDataframe *random = [template uniformSampling:5000];
    [random addSamplesWithData:[template allSamples]];
    NSDictionary *randomMins = [template stat:@"min"];
    NSDictionary *randomMaxs = [template stat:@"max"];
    YCDataframe *corrupt = [random copy];
    [corrupt corruptWithProbability:1.0 relativeMagnitude:0.5];
    NSDictionary *corruptMins = [corrupt stat:@"min"];
    NSDictionary *corruptMaxs = [corrupt stat:@"max"];
    XCTAssert([randomMins isEqualToDictionary:corruptMins], @"Minimums are not maintained");
    XCTAssert([randomMaxs isEqualToDictionary:corruptMaxs], @"Maximums are not maintained");
    
}

- (void)testReplaceRow
{
//    YCDataframe *df = [self randomDataframeColumns:5 rows:10];
//    NSDictionary *newRow = @{@1.0, @1.0, @1.0, @1.0, @1.0};
//    [df replaceSampleAtIndex:2 withData:newRow];
//    NSDictionary *retrievedRow = [df sampleAtIndex:2];
//    NSAssertEqual(newRow, retrievedRow, @"Result not equal");
}

- (void)testOrderedDictionary
{
    MutableOrderedDictionary *dictionary = [MutableOrderedDictionary dictionary];
    dictionary[@"test"] = @"test";
    XCTAssertEqualObjects(dictionary[@"test"], @"test", @"Strings not equal");
}

- (void)testYCMutableArray
{
    YCMutableArray *array = [YCMutableArray arrayWithArray:@[@1, @2, @3]];
    
    YCMutableArray *copy = [array mutableCopy];
    
    NSLog(@"%@", [copy class]);
    XCTAssert([copy isKindOfClass:[YCMutableArray class]], @"Copy not of the required class");
    
    YCMutableArray *derivative = [YCMutableArray arrayWithArray:array];
    
    XCTAssert([derivative isKindOfClass:[YCMutableArray class]], @"Copy not of the required class");
}

@end
