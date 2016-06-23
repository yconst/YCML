//
//  YCMLRBMTests.m
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

#import <XCTest/XCTest.h>
@import YCMatrix;
@import YCML;
#import "CHCSVParser.h"

// Convenience logging function (without date/object)
#define CleanLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface YCMLRBMTests : XCTestCase

@end

@implementation YCMLRBMTests

// The tests below are initial ones to test basic model functionality.

- (void)testBinaryRBMActivation
{
    YCBinaryRBM *model = [[YCBinaryRBM alloc] init];
    
    // Here create input
    double inputArray[3] = {1.0, 0.0, 0.0};
    Matrix *input = [Matrix matrixFromArray:inputArray rows:3 columns:1];
    
    double w[12] = {3.40, -1.14, 6.18,
        2.32, -12.10, -0.50,
        1.22, 1.49, -1.30,
        -0.20, 1.01, 0.12};
    model.weights = [Matrix matrixFromArray:w rows:4 columns:3];
    
    double vb[3] = {-1.4,
        1.07,
        0.190};
    model.visibleBiases = [Matrix matrixFromArray:vb rows:3 columns:1];
    
    double hb[4] = {-5.4,
        1.2,
        0.21,
        -0.44};
    model.hiddenBiases = [Matrix matrixFromArray:hb rows:4 columns:1];
    
    // Here test net
    Matrix *actual = [model propagateToHidden:input];
    
    double e[4] = {0.119203,
        0.971252,
        0.806901,
        0.345247};
    Matrix *expected = [Matrix matrixFromArray:e rows:4 columns:1];
    
    CleanLog(@"%@", actual);
    XCTAssert([expected isEqualToMatrix:actual tolerance:0.00001],
              @"Hidden matrix is not equal to expected");
    
    // Let's do some sampling as well
    Matrix *gibbsStep = [model sampleVisibleGivenHidden:[model sampleHiddenGivenVisible:input]];
    
    CleanLog(@"%@", gibbsStep);
}

- (void)testBinaryRBMFreeEnergy
{
    YCBinaryRBM *model = [[YCBinaryRBM alloc] init];
    
    double inputArray[3] = {0.0, 0.0, 0.0};
    Matrix *input = [Matrix matrixFromArray:inputArray rows:3 columns:1];
    
    double w[12] = {3.40, -1.14, 6.18,
        2.32, -12.10, -0.50,
        1.22, 1.49, -1.30,
        -0.20, 1.01, 0.12};
    model.weights = [Matrix matrixFromArray:w rows:4 columns:3];
    
    double vb[3] = {-1.4,
        1.07,
        0.190};
    model.visibleBiases = [Matrix matrixFromArray:vb rows:3 columns:1];
    
    double hb[4] = {-5.4,
        1.2,
        0.21,
        -0.44};
    model.hiddenBiases = [Matrix matrixFromArray:hb rows:4 columns:1];
    
    CleanLog(@"%@", [model freeEnergy:input]);
}

- (void)testBinaryRBMParameterVectorEncoding
{
    double ia[9] = {9.4084028, -1.14962953, 6.912,
        2.27, -12.1076, -9.691,
        1.7603, 1.4902, -3.8019};
    Matrix *im = [Matrix matrixFromArray:ia rows:3 columns:3];
    
    YCBinaryRBM *model = [[YCBinaryRBM alloc] init];
    model.weights = [Matrix matrixOfRows:3 columns:5];
    model.hiddenBiases = [Matrix matrixOfRows:3 columns:1];
    model.visibleBiases = [Matrix matrixOfRows:5 columns:1];
    
    YCCDProblem *prob = [[YCCDProblem alloc] initWithInputMatrix:im model:model];
    
    int parameterCount = model.visibleSize * model.hiddenSize + model.visibleSize + model.hiddenSize;
    
    Matrix *lo = [Matrix matrixOfRows:parameterCount columns:1 value:0.0];
    Matrix *hi = [Matrix matrixOfRows:parameterCount columns:1 value:5.0];
    Matrix *params = [Matrix uniformRandomLowerBound:lo upperBound:hi];
    
    Matrix *weights = [prob weightsWithParameters:params];
    Matrix *vBiases = [prob visibleBiasWithParameters:params];
    Matrix *hBiases = [prob hiddenBiasWithParameters:params];

    Matrix *trialParams = [Matrix matrixLike:params];
    
    [prob storeWeights:weights visibleBiases:vBiases hiddenBiases:hBiases toVector:trialParams];
    XCTAssertEqualObjects(params, trialParams, @"Converted parameter vector is not equal");
}

- (void)testBinaryRBMTraining
{
    double samples[] = {
        // M T W T F S S
        1,0,0,0,0,0,0,
        0,1,0,0,0,0,0,
        1,0,0,0,0,0,0,
        0,1,0,0,0,0,0,
        0,0,1,0,0,0,0,
        1,0,0,0,0,0,0,
        0,1,0,0,0,0,0,
        0,0,1,0,0,0,0,
        0,0,0,0,0,0,1};
    Matrix *samplesMatrix = [[Matrix matrixFromArray:samples rows:4 columns:7] matrixByTransposing];
    YCCDTrainer *trainer = [YCCDTrainer trainer];
    YCBinaryRBM *model = [trainer train:nil inputMatrix:samplesMatrix];
    Matrix *s1 = [Matrix matrixFromNSArray:@[@1, @0, @0, @0, @0, @0, @0] rows:7 columns:1];
    Matrix *s2 = [Matrix matrixFromNSArray:@[@0, @1, @0, @0, @0, @0, @0] rows:7 columns:1];
    Matrix *s3 = [Matrix matrixFromNSArray:@[@0, @0, @0, @0, @1, @0, @0] rows:7 columns:1];
    Matrix *s4 = [Matrix matrixFromNSArray:@[@0, @0, @0, @0, @0, @0, @1] rows:7 columns:1];
    CleanLog(@"Out Mon: %@, E: %@", [model gibbsStep:s1], [model freeEnergy:s1]);
    CleanLog(@"Out Tue: %@, E: %@", [model gibbsStep:s2], [model freeEnergy:s2]);
    CleanLog(@"Out Fri: %@, E: %@", [model gibbsStep:s3], [model freeEnergy:s3]);
    CleanLog(@"Out Sun: %@, E: %@", [model gibbsStep:s4], [model freeEnergy:s4]);
}

- (void)testBinaryRBMTrainingMNIST
{
    Matrix *mnist = [self matrixWithCSVName:@"mnist_train_1_to_37"];
    YCCDTrainer *trainer = [YCCDTrainer trainer];
    [trainer train:nil inputMatrix:mnist];
}

- (Matrix *)matrixWithCSVName:(NSString *)path
{
    NSBundle *bundle       = [NSBundle bundleForClass:[self class]];
    NSString *filePath     = [bundle pathForResource:path ofType:@"csv"];
    NSString* fileContents = [NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    NSMutableArray *arrays = [[fileContents CSVComponents] mutableCopy];
   
    NSMutableArray *cols = [NSMutableArray array];
    for (NSArray *a in arrays)
    {
        [cols addObject:[Matrix matrixFromNSArray:a rows:(int)(a.count) columns:1]];
    }
    return [Matrix matrixFromColumns:cols]; // Transpose to have one sample per column
}

@end
