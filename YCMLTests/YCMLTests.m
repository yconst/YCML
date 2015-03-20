//
//  YCMLTests.m
//  YCMLTests
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

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
@import YCML;
@import YCMatrix;

// Convenience logging function (without date/object)
#define CleanLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface YCMLTests : XCTestCase

@end

@implementation YCMLTests

#pragma mark FeedForward Net Tests

- (void)testFFNctivation
{
    YCFFN *net = [[YCFFN alloc] init];
    
    // Here create input
    double inputArray[3] = {1.0, 0.4, 0.1};
    Matrix *input = [Matrix matrixFromArray:inputArray Rows:3 Columns:1];
    
    // Here create expected output
    double outputArray[1] = {0.0031514511414750075};
    Matrix *expected = [Matrix matrixFromArray:outputArray Rows:1 Columns:1];
    // Here create weight and biases matrices
    NSMutableArray *weights = [NSMutableArray array];
    NSMutableArray *biases = [NSMutableArray array];
    
    double layer01w[9] = {9.408402885852626, -1.1496369471492953, 6.189778876161912,
        2.3211275791148727, -12.103229230238776, -9.508202761587691,
        1.222394739197603, 1.4906291343919522, -13.304211439238019};
    [weights addObject:[Matrix matrixFromArray:layer01w Rows:3 Columns:3]];
    double layer12w[3] = {11.892952707820495,
        -13.023554005003948,
        -11.998042608132318};
    [weights addObject:[Matrix matrixFromArray:layer12w Rows:3 Columns:1]];
    
    double layer01b[3] = {-5.421832727047451,
        8.272508982078136,
        10.113971776662758};
    [biases addObject:[Matrix matrixFromArray:layer01b Rows:3 Columns:1]];
    double layer12b[1] = {6.395286202809748};
    [biases addObject:[Matrix matrixFromArray:layer12b Rows:1 Columns:1]];
    
    // Here apply weight ans biases matrices to net
    net.weightMatrices = weights;
    net.biasVectors = biases;
    
    // Here test net
    Matrix *actual = [net activateWithMatrix:input];
    
    XCTAssertEqualObjects(expected, actual, @"Predicted matrix is not equal to expected");
}

- (void)testFFNParameterVectorEncoding
{
    double ia[9] = {9.4084028, -1.14962953, 6.912,
        2.27, -12.1076, -9.691,
        1.7603, 1.4902, -3.8019};
    double oa[3] = {11.895, -3.0235540050, -1.2318};
    Matrix *im = [Matrix matrixFromArray:ia Rows:3 Columns:3];
    Matrix *om = [Matrix matrixFromArray:oa Rows:1 Columns:3];
    
    YCFFN *model = [[YCFFN alloc] init];
    model.weightMatrices = @[[Matrix matrixOfRows:3 Columns:5],
                             [Matrix matrixOfRows:5 Columns:1]];
    model.biasVectors = @[[Matrix matrixOfRows:5 Columns:1],
                          [Matrix matrixOfRows:1 Columns:1]];
    
    YCBackPropProblem *prob = [[YCBackPropProblem alloc] initWithInputMatrix:im
                                                                outputMatrix:om
                                                                       model:model];
    Matrix *lo = [Matrix matrixOfRows:26 Columns:1 Value:0.0]; // 3x5 + 5 + 1x5 + 1
    Matrix *hi = [Matrix matrixOfRows:26 Columns:1 Value:5.0];
    Matrix *params = [Matrix randomValuesMatrixWithLowerBound:lo upperBound:hi];
    NSArray *weights = [prob modelWeightsWithParameters:params];
    NSArray *biases = [prob modelBiasesWithParameters:params];
    Matrix *trialParams = [Matrix matrixLike:params];
    
    [prob storeWeights:weights biases:biases toVector:trialParams];
    XCTAssertEqualObjects(params, trialParams, @"Converted parameter vector is not equal");
}

- (void)testFFNNumericalGradients
{
    double ia[9] = {0.4084028, 0.14962953, 0.912,
        0.27, 0.1076, 0.691,
        0.7603, 0.4902, 0.8019};
    double oa[3] = {0.1, 0.95, 0.45};
    Matrix *im = [Matrix matrixFromArray:ia Rows:3 Columns:3];
    Matrix *om = [Matrix matrixFromArray:oa Rows:1 Columns:3];
    
    YCFFN *model = [[YCFFN alloc] init];
    model.weightMatrices = @[[Matrix matrixOfRows:3 Columns:2],
                             [Matrix matrixOfRows:2 Columns:1]];
    model.biasVectors = @[[Matrix matrixOfRows:2 Columns:1],
                          [Matrix matrixOfRows:1 Columns:1]];
    
    YCBackPropProblem *prob = [[YCBackPropProblem alloc] initWithInputMatrix:im
                                                                outputMatrix:om
                                                                       model:model];
    Matrix *lo     = [Matrix matrixOfRows:11 Columns:1 Value:-1.0]; // 3x2 + 2 + 1x2 + 1
    Matrix *hi     = [Matrix matrixOfRows:11 Columns:1 Value:1.0];
    Matrix *params = [Matrix randomValuesMatrixWithLowerBound:lo upperBound:hi];
    
    Matrix *theoreticalGradients = [Matrix matrixLike:params];
    [prob derivatives:theoreticalGradients parameters:params];
    Matrix *numericalGradients   = [Matrix matrixLike:theoreticalGradients];
    Matrix *perturbed            = [Matrix matrixFromMatrix:params];
    double e                       = 1E-4;
    Matrix *resultMin = [Matrix matrixOfRows:1 Columns:1];
    Matrix *resultMax = [Matrix matrixOfRows:1 Columns:1];
    for (int i=0; i<[perturbed count]; i++)
    {
        perturbed->matrix[i] -= e;
        [prob evaluate:resultMin parameters:perturbed];
        perturbed->matrix[i] += 2*e;
        [prob evaluate:resultMax parameters:perturbed];
        perturbed->matrix[i] -= e;
        numericalGradients->matrix[i] = (resultMax->matrix[0] - resultMin->matrix[0]) / (2*e);
    }
    CleanLog(@"Theoretical: %@", [theoreticalGradients matrixByTransposing]);
    CleanLog(@"Numerical: %@", [numericalGradients matrixByTransposing]);
    CleanLog(@"Difference: %@", [[theoreticalGradients matrixBySubtracting:numericalGradients] matrixByTransposing]);
    XCTAssert([numericalGradients isEqualToMatrix:theoreticalGradients tolerance:1E-8], @"Matrices are not equal");
}

#pragma mark Cross-Validation Tests

- (void)testELMHousing
{
    YCELMTrainer *trainer                  = [YCELMTrainer trainer];
    trainer.settings[@"C"]                 = @8;
    trainer.settings[@"Hidden Layer Size"] = @900;
    
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableIndex:13 rmse:6.0];
}

- (void)testBackPropHousing
{
    YCBackPropTrainer *trainer              = [YCBackPropTrainer trainer];
    trainer.settings[@"Hidden Layer Size"]  = @8;
    trainer.settings[@"Lambda"]             = @0.0001;
    trainer.settings[@"Iterations"]         = @1500;
    trainer.settings[@"Alpha"]              = @0.5;
    
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableIndex:13 rmse:6.0];
}

#pragma mark Utility Functions

- (void)testWithTrainer:(YCSupervisedTrainer *)trainer
                                dataset:(NSString *)dataset
                 dependentVariableIndex:(int)index
                                   rmse:(double)rmse
{
    // Training + cross-validation
    Matrix *trainingData   = [self matrixWithCSVName:dataset removeFirst:YES];
    [trainingData shuffleColumns];
    Matrix *cvData         = [trainingData matrixWithColumnsInRange:NSMakeRange(trainingData.columns - 30, 29)];
    trainingData             = [trainingData matrixWithColumnsInRange:NSMakeRange(0, trainingData.columns - 30)];
    Matrix *trainingOutput = [trainingData getRow:index];
    Matrix *trainingInput  = [trainingData removeRow:index];
    Matrix *cvOutput       = [cvData getRow:index];
    Matrix *cvInput        = [cvData removeRow:index];
    
    YCFFN *model = (YCFFN *)[trainer train:nil
                               inputMatrix:trainingInput
                              outputMatrix:trainingOutput];
    
    Matrix *predictedOutput = [model activateWithMatrix:cvInput];
    
    [predictedOutput subtract:cvOutput];
    [predictedOutput elementWiseMultiply:predictedOutput];
    double RMSE = sqrt( (1.0/[predictedOutput count]) * [predictedOutput sum] );
    CleanLog(@"RMSE: %f", RMSE);
    XCTAssertLessThan(RMSE, rmse, @"RMSE above threshold");
}

- (Matrix *)matrixWithCSVName:(NSString *)path removeFirst:(BOOL)removeFirst
{
    Matrix *output;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *filePath = [bundle pathForResource:@"housing" ofType:@"csv"];
    
    NSString* fileContents = [NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    fileContents = [fileContents stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    NSMutableArray* rows = [[fileContents componentsSeparatedByString:@"\n"] mutableCopy];
    if (removeFirst)
    {
        [rows removeObjectAtIndex:0];
    }
    int counter = 0;
    for (NSString *row in rows)
    {
        NSArray *fields = [row componentsSeparatedByString:@","];
        if (!output)
        {
            output = [Matrix matrixOfRows:(int)[fields count]
                                    Columns:(int)[rows count]];
            
        }
        [output setColumn:counter++ Value:[Matrix matrixFromNSArray:fields
                                                                 Rows:(int)[fields count]
                                                              Columns:1]];
    }
    return output;
}

@end
