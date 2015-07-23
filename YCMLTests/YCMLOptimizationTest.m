//
//  YCMLOptimizationTest.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 28/3/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
//

@import XCTest;
@import YCML;
@import YCMatrix;

// Convenience logging function (without date/object)
#define CleanLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);


@interface YCProblemGD:NSObject <YCDerivativeProblem>

@end

@implementation YCProblemGD

- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters
{
    double x1 = [parameters valueAtRow:0 Column:0] + 5.0;
    double x2 = [parameters valueAtRow:1 Column:0] + 2.0;
    [target setValue:x1*x1 + x2*x2 Row:0 Column:0];
}

- (void)derivatives:(Matrix *)target parameters:(Matrix *)parameters
{
    double x1 = [parameters valueAtRow:0 Column:0] + 5.0;
    double x2 = [parameters valueAtRow:1 Column:0] + 2.0;
    [target setValue:2*x1 Row:0 Column:0];
    [target setValue:2*x2 Row:1 Column:0];
}

- (Matrix *)parameterBounds
{
    Matrix *bounds = [Matrix matrixOfRows:[self parameterCount] Columns:2];
    
    for (int i=0; i<self.parameterCount; i++)
    {
        [bounds setValue:-1 Row:i Column:0];
        [bounds setValue:1 Row:i Column:1];
    }
    return bounds;
}

- (Matrix *)initialValuesRangeHint
{
    return [self parameterBounds];
}

- (int)parameterCount
{
    return 2;
}

- (int)objectiveCount
{
    return 1;
}

- (int)constraintCount
{
    return 0;
}

@end


@interface YCProblemZDT1 :NSObject <YCProblem>

@end

@implementation YCProblemZDT1

- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters
{
    // ZDT1
    
    NSUInteger n = [parameters count];
    
    double f1 = [parameters valueAtRow:0 Column:0];
    
    double accu = 0;
    
    for (int i=1; i<n; i++)
    {
        accu += [parameters valueAtRow:i Column:0];
    }
    double g = 1.0 + (9 / (n - 1)) * accu;
    
    double f2 = g * (1.0 - sqrt(f1/g));
    
    [target setValue:f1 Row:0 Column:0];
    [target setValue:f2 Row:1 Column:0];
}

- (Matrix *)parameterBounds
{
    Matrix *bounds = [Matrix matrixOfRows:[self parameterCount] Columns:2];
    
    for (int i=0; i<self.parameterCount; i++)
    {
        [bounds setValue:0 Row:i Column:0];
        [bounds setValue:1 Row:i Column:1];
    }
    return bounds;
}

- (Matrix *)initialValuesRangeHint
{
    return [self parameterBounds];
}

- (int)parameterCount
{
    return 5;
}

- (int)objectiveCount
{
    return 2;
}

- (int)constraintCount
{
    return 0;
}

@end


@interface YCMLOptimizationTest : XCTestCase

@end

@implementation YCMLOptimizationTest

- (void)testGradientDescent
{
    YCProblemGD *gdProblem = [[YCProblemGD alloc] init];
    YCOptimizer *gd = [[YCGradientDescent alloc] initWithProblem:gdProblem];
    gd.settings[@"Iterations"] = @2000;
    [gd run];
    Matrix *result = [Matrix matrixOfRows:1 Columns:1];
    [gdProblem evaluate:result parameters:gd.state[@"values"]];
    XCTAssertLessThan([result valueAtRow:0 Column:0], 0.02);
}

- (void)testRPropDescent
{
    YCProblemGD *gdProblem = [[YCProblemGD alloc] init];
    YCOptimizer *gd = [[YCRProp alloc] initWithProblem:gdProblem];
    gd.settings[@"Iterations"] = @100;
    [gd run];
    Matrix *result = [Matrix matrixOfRows:1 Columns:1];
    [gdProblem evaluate:result parameters:gd.state[@"values"]];
    XCTAssertLessThan([result valueAtRow:0 Column:0], 0.01);
}

- (void)testZDT1
{
    YCProblemZDT1 *zdt1 = [[YCProblemZDT1 alloc] init];
    YCOptimizer *ga = [[YCNSGAII alloc] initWithProblem:zdt1];
    ga.settings[@"Iterations"] = @50;
    [ga run];
    //Matrix *result = [Matrix matrixOfRows:1 Columns:1];
    //[gdProblem evaluate:result parameters:gd.state[@"values"]];
    //XCTAssertLessThan([result valueAtRow:0 Column:0], 0.02);
}

@end
