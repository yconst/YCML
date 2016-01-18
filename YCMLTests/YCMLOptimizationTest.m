//
//  YCMLOptimizationTest.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 2/3/15.
//  Copyright (c) 2015-2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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
    double x1 = [parameters valueAtRow:0 column:0] + 5.0;
    double x2 = [parameters valueAtRow:1 column:0] + 2.0;
    [target setValue:x1*x1 + x2*x2 row:0 column:0];
}

- (void)derivatives:(Matrix *)target parameters:(Matrix *)parameters
{
    double x1 = [parameters valueAtRow:0 column:0] + 5.0;
    double x2 = [parameters valueAtRow:1 column:0] + 2.0;
    [target setValue:2*x1 row:0 column:0];
    [target setValue:2*x2 row:1 column:0];
}

- (Matrix *)parameterBounds
{
    Matrix *bounds = [Matrix matrixOfRows:[self parameterCount] columns:2];
    
    for (int i=0; i<self.parameterCount; i++)
    {
        [bounds setValue:-1 row:i column:0];
        [bounds setValue:1 row:i column:1];
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

- (Matrix *)modes
{
    return [Matrix matrixOfRows:1 columns:1 value:0];
}

- (YCEvaluationMode)supportedEvaluationMode
{
    return YCRequiresSequentialEvaluation;
}

@end


@interface YCProblemZDT1 :NSObject <YCProblem>

@end

@implementation YCProblemZDT1

- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters
{
    // ZDT1
    
    NSUInteger n = [parameters count];
    
    double f1 = [parameters valueAtRow:0 column:0];
    
    double accu = 0;
    
    for (int i=1; i<n; i++)
    {
        accu += [parameters valueAtRow:i column:0];
    }
    double g = 1.0 + (9 / (n - 1)) * accu;
    
    double f2 = g * (1.0 - sqrt(f1/g));
    
    [target setValue:f1 row:0 column:0];
    [target setValue:f2 row:1 column:0];
}

- (Matrix *)parameterBounds
{
    Matrix *bounds = [Matrix matrixOfRows:[self parameterCount] columns:2];
    
    for (int i=0; i<self.parameterCount; i++)
    {
        [bounds setValue:0 row:i column:0];
        [bounds setValue:1 row:i column:1];
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

- (Matrix *)modes
{
    return [Matrix matrixOfRows:2 columns:1 value:0];
}

- (YCEvaluationMode)supportedEvaluationMode
{
    return YCRequiresSequentialEvaluation;
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
    Matrix *result = [Matrix matrixOfRows:1 columns:1];
    [gdProblem evaluate:result parameters:gd.state[@"values"]];
    XCTAssertLessThan([result valueAtRow:0 column:0], 0.02);
}

- (void)testRPropDescent
{
    YCProblemGD *gdProblem = [[YCProblemGD alloc] init];
    YCOptimizer *gd = [[YCRProp alloc] initWithProblem:gdProblem];
    gd.settings[@"Iterations"] = @100;
    [gd run];
    Matrix *result = [Matrix matrixOfRows:1 columns:1];
    [gdProblem evaluate:result parameters:gd.state[@"values"]];
    XCTAssertLessThan([result valueAtRow:0 column:0], 0.01);
}

- (void)testNSGAIIZDT1
{
    YCProblemZDT1 *zdt1 = [[YCProblemZDT1 alloc] init];
    
    Matrix *lower = [Matrix matrixOfRows:2 columns:1 value:0];
    Matrix *upper = [Matrix matrixOfRows:2 columns:1 value:1];
    
    YCOptimizer *ga = [[YCNSGAII alloc] initWithProblem:zdt1];
    ga.settings[@"Iterations"] = @200;
    
    [ga run];
    
    double I = [[[YCHypervolumeMetric alloc] init]
                estimateHypervolumeForObjectiveFunctionVectors:ga.bestObjectives
                targets:zdt1.modes
                sampleSize:5000
                lowerReference:lower
                upperReference:upper];
    
    NSLog(@"Hypervolume indicator for NSGA-II, ZDT1, 200 generations: %f", I);
    NSAssert(I>0.6, @"NSGA-II Hypervolume indicator below threshold");
}

- (void)testHypEZDT1
{
    YCProblemZDT1 *zdt1 = [[YCProblemZDT1 alloc] init];
    
    Matrix *lower = [Matrix matrixOfRows:2 columns:1 value:0];
    Matrix *upper = [Matrix matrixOfRows:2 columns:1 value:1];
    
    YCOptimizer *ga = [[YCHypE alloc] initWithProblem:zdt1];
    ga.settings[@"Iterations"] = @200;
    
    [ga run];
    
    double I = [[[YCHypervolumeMetric alloc] init]
                estimateHypervolumeForObjectiveFunctionVectors:ga.bestObjectives
                targets:zdt1.modes
                sampleSize:5000
                lowerReference:lower
                upperReference:upper];
    
    NSLog(@"Hypervolume indicator for HypE, ZDT1, 200 generations: %f", I);
    NSAssert(I>0.6, @"HypE Hypervolume indicator below threshold");
}

- (void)testReplacingPopulation
{
    YCProblemZDT1 *zdt1 = [[YCProblemZDT1 alloc] init];
    YCPopulationBasedOptimizer *ga1 = [[YCNSGAII alloc] initWithProblem:zdt1
                                                               settings:@{@"Population Size": @150}];
    
    NSArray *solutions = [ga1 bestParameters];
    Matrix *solutionsMatrix = [Matrix matrixFromColumns:solutions];
    
    YCPopulationBasedOptimizer *ga2 = [[YCNSGAII alloc] initWithProblem:zdt1
                                                               settings:@{@"Population Size": @50}];
    [ga2 replacePopulationUsing:solutionsMatrix];
    
    XCTAssertEqual(ga2.population.count, ga1.population.count);
    XCTAssertEqual([ga2.settings[@"Population Size"] unsignedIntValue], ga2.population.count);
    
    ga2.settings[@"Iterations"] = @50;
    [ga2 run];
}

@end
