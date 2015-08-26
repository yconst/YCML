//
//  YCMLRBMTests.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 18/8/15.
//  Copyright © 2015 Yannis Chatzikonstantinou. All rights reserved.
//

#import <XCTest/XCTest.h>
@import YCMatrix;
@import YCML;

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
    Matrix *input = [Matrix matrixFromArray:inputArray Rows:3 Columns:1];
    
    double w[12] = {3.40, -1.14, 6.18,
        2.32, -12.10, -0.50,
        1.22, 1.49, -1.30,
        -0.20, 1.01, 0.12};
    model.weights = [Matrix matrixFromArray:w Rows:4 Columns:3];
    
    double vb[3] = {-1.4,
        1.07,
        0.190};
    model.visibleBiases = [Matrix matrixFromArray:vb Rows:3 Columns:1];
    
    double hb[4] = {-5.4,
        1.2,
        0.21,
        -0.44};
    model.hiddenBiases = [Matrix matrixFromArray:hb Rows:4 Columns:1];
    
    // Here test net
    Matrix *actual = [model propagateToHidden:input];
    
    double e[4] = {0.119203,
        0.971252,
        0.806901,
        0.345247};
    Matrix *expected = [Matrix matrixFromArray:e Rows:4 Columns:1];
    
    CleanLog(@"%@", actual);
    XCTAssert([expected isEqualToMatrix:actual tolerance:0.00001],
              @"Hidden matrix is not equal to expected");
    
    // Let's do some sampling as well
    Matrix *gibbs = [model sampleHiddenGivenVisible:[model sampleVisibleGivenHidden:input]];
    
    CleanLog(@"%@", gibbs);
}

- (void)testBinaryRBMFreeEnergy
{
    YCBinaryRBM *model = [[YCBinaryRBM alloc] init];
    
    double inputArray[3] = {0.0, 0.0, 0.0};
    Matrix *input = [Matrix matrixFromArray:inputArray Rows:3 Columns:1];
    
    double w[12] = {3.40, -1.14, 6.18,
        2.32, -12.10, -0.50,
        1.22, 1.49, -1.30,
        -0.20, 1.01, 0.12};
    model.weights = [Matrix matrixFromArray:w Rows:4 Columns:3];
    
    double vb[3] = {-1.4,
        1.07,
        0.190};
    model.visibleBiases = [Matrix matrixFromArray:vb Rows:3 Columns:1];
    
    double hb[4] = {-5.4,
        1.2,
        0.21,
        -0.44};
    model.hiddenBiases = [Matrix matrixFromArray:hb Rows:4 Columns:1];
    
    CleanLog(@"%@", [model freeEnergy:input]);
}

- (void)testBinaryRBMParameterVectorEncoding
{
    double ia[9] = {9.4084028, -1.14962953, 6.912,
        2.27, -12.1076, -9.691,
        1.7603, 1.4902, -3.8019};
    Matrix *im = [Matrix matrixFromArray:ia Rows:3 Columns:3];
    
    YCBinaryRBM *model = [[YCBinaryRBM alloc] init];
    model.weights = [Matrix matrixOfRows:3 Columns:5];
    model.hiddenBiases = [Matrix matrixOfRows:3 Columns:1];
    model.visibleBiases = [Matrix matrixOfRows:5 Columns:1];
    
    YCBinaryRBMProblem *prob = [[YCBinaryRBMProblem alloc] initWithInputMatrix:im model:model];
    
    int parameterCount = model.visibleSize * model.hiddenSize + model.visibleSize + model.hiddenSize;
    
    Matrix *lo = [Matrix matrixOfRows:parameterCount Columns:1 Value:0.0];
    Matrix *hi = [Matrix matrixOfRows:parameterCount Columns:1 Value:5.0];
    Matrix *params = [Matrix randomValuesMatrixWithLowerBound:lo upperBound:hi];
    
    Matrix *weights = [prob weightsWithParameters:params];
    Matrix *vBiases = [prob visibleBiasWithParameters:params];
    Matrix *hBiases = [prob hiddenBiasWithParameters:params];

    Matrix *trialParams = [Matrix matrixLike:params];
    
    [prob storeWeights:weights visibleBiases:vBiases hiddenBiases:hBiases toVector:trialParams];
    XCTAssertEqualObjects(params, trialParams, @"Converted parameter vector is not equal");
}

@end
