//
//  YCMLTests.m
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

@import Foundation;
@import XCTest;
@import YCML;
@import YCMatrix;
#import "CHCSVParser.h"

// Convenience logging function (without date/object)
#define CleanLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface YCMLTests : XCTestCase

@end

@implementation YCMLTests

#pragma mark FeedForward Net Tests

- (void)testFFNActivation
{
    YCFFN *net = [[YCFFN alloc] init];
    
    // Here create input
    double inputArray[3] = {1.0, 0.4, 0.1};
    Matrix *input = [Matrix matrixFromArray:inputArray rows:3 columns:1];
    
    // Here create expected output
    double outputArray[1] = {-5.75673582497026004};
    Matrix *expected = [Matrix matrixFromArray:outputArray rows:1 columns:1];
    // Here create weight and biases matrices
    NSMutableArray *weights = [NSMutableArray array];
    NSMutableArray *biases = [NSMutableArray array];
    
    double layer01w[9] = {9.408402885852626, -1.1496369471492953, 6.189778876161912,
        2.3211275791148727, -12.103229230238776, -9.508202761587691,
        1.222394739197603, 1.4906291343919522, -13.304211439238019};
    [weights addObject:[Matrix matrixFromArray:layer01w rows:3 columns:3]];
    double layer12w[3] = {11.892952707820495,
        -13.023554005003948,
        -11.998042608132318};
    [weights addObject:[Matrix matrixFromArray:layer12w rows:3 columns:1]];
    
    double layer01b[3] = {-5.421832727047451,
        8.272508982078136,
        10.113971776662758};
    [biases addObject:[Matrix matrixFromArray:layer01b rows:3 columns:1]];
    double layer12b[1] = {6.395286202809748};
    [biases addObject:[Matrix matrixFromArray:layer12b rows:1 columns:1]];
    
    // Here apply weight ans biases matrices to net
    NSMutableArray *layers = [NSMutableArray array];
    for (int i=0; i<weights.count; i++)
    {
        YCFullyConnectedLayer *l;
        if (i < weights.count - 1)
        {
            l =  [[YCSigmoidLayer alloc] init];
        }
        else
        {
            l =  [[YCLinearLayer alloc] init];
        }
        l.weightMatrix = weights[i];
        l.biasVector = biases[i];
        [layers addObject: l];
    }
    net.layers = layers;
    
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
    Matrix *im = [Matrix matrixFromArray:ia rows:3 columns:3];
    Matrix *om = [Matrix matrixFromArray:oa rows:1 columns:3];
    
    YCFFN *model = [[YCFFN alloc] init];
    
    YCSigmoidLayer *hl = [YCSigmoidLayer layerWithInputSize:3 outputSize:5];
    YCSigmoidLayer *ol = [YCSigmoidLayer layerWithInputSize:5 outputSize:1];
    
    model.layers = @[hl, ol];
    
    YCBackPropProblem *prob = [[YCBackPropProblem alloc] initWithInputMatrix:im
                                                                outputMatrix:om
                                                                       model:model];
    Matrix *lo = [Matrix matrixOfRows:26 columns:1 value:0.0]; // 3x5 + 5 + 1x5 + 1
    Matrix *hi = [Matrix matrixOfRows:26 columns:1 value:5.0];
    Matrix *params = [Matrix randomValuesMatrixWithLowerBound:lo upperBound:hi];
    NSArray *weights = [prob modelWeightsWithParameters:params];
    NSArray *biases = [prob modelBiasesWithParameters:params];
    Matrix *trialParams = [Matrix matrixLike:params];
    
    [prob storeWeights:weights biases:biases toVector:trialParams];
    XCTAssertEqualObjects(params, trialParams, @"Converted parameter vector is not equal");
}

- (void)testFFNSigSigNumericalGradients
{
    YCFullyConnectedLayer *hl = [YCSigmoidLayer layerWithInputSize:3 outputSize:2];
    YCFullyConnectedLayer *ol = [YCSigmoidLayer layerWithInputSize:2 outputSize:1];
    [self numericalGradientsWithLayers:@[hl, ol]];
}

- (void)testFFNSigLinNumericalGradients
{
    YCFullyConnectedLayer *hl = [YCSigmoidLayer layerWithInputSize:3 outputSize:2];
    YCFullyConnectedLayer *ol = [YCLinearLayer layerWithInputSize:2 outputSize:1];
    [self numericalGradientsWithLayers:@[hl, ol]];
}

- (void)testFFNTanhLinNumericalGradients
{
    YCFullyConnectedLayer *hl = [YCTanhLayer layerWithInputSize:3 outputSize:2];
    YCFullyConnectedLayer *ol = [YCLinearLayer layerWithInputSize:2 outputSize:1];
    [self numericalGradientsWithLayers:@[hl, ol]];
}

- (void)testFFNReLULinNumericalGradients
{
    YCFullyConnectedLayer *hl = [YCReLULayer layerWithInputSize:3 outputSize:2];
    YCFullyConnectedLayer *ol = [YCLinearLayer layerWithInputSize:2 outputSize:1];
    [self numericalGradientsWithLayers:@[hl, ol]];
}

- (void)testFFNExoticNetNumericalGradients
{
    YCFullyConnectedLayer *hl1 = [YCReLULayer layerWithInputSize:3 outputSize:3];
    YCFullyConnectedLayer *hl2 = [YCLinearLayer layerWithInputSize:3 outputSize:3];
    YCFullyConnectedLayer *hl3 = [YCSigmoidLayer layerWithInputSize:3 outputSize:2];
    YCFullyConnectedLayer *ol = [YCLinearLayer layerWithInputSize:2 outputSize:1];
    [self numericalGradientsWithLayers:@[hl1, hl2, hl3, ol]];
}

- (void)numericalGradientsWithLayers:(NSArray *)layers
{
    double ia[12] = {0.4084028, 0.14962953, 0.912, 0.877,
        0.27, 0.1076, 0.691, 0.052,
        0.7603, 0.4902, 0.8019, 0.23};
    double oa[4] = {0.1, 0.95, 0.45, 0.21};
    Matrix *im = [Matrix matrixFromArray:ia rows:3 columns:4];
    Matrix *om = [Matrix matrixFromArray:oa rows:1 columns:4];
    
    YCFFN *model = [[YCFFN alloc] init];
    
    model.layers = layers;
    
    YCBackPropProblem *prob = [[YCBackPropProblem alloc] initWithInputMatrix:im
                                                                outputMatrix:om
                                                                       model:model];
    int parameterCount = 0;
    for (YCFullyConnectedLayer *l in layers)
    {
        parameterCount += l.weightMatrix.count + l.biasVector.count;
    }
    Matrix *lo     = [Matrix matrixOfRows:parameterCount columns:1 value:-1.0];
    Matrix *hi     = [Matrix matrixOfRows:parameterCount columns:1 value:1.0];
    Matrix *params = [Matrix randomValuesMatrixWithLowerBound:lo upperBound:hi];
    
    Matrix *theoreticalGradients = [Matrix matrixLike:params];
    [prob derivatives:theoreticalGradients parameters:params];
    Matrix *numericalGradients   = [Matrix matrixLike:theoreticalGradients];
    Matrix *perturbed            = [Matrix matrixFromMatrix:params];
    double e                     = 1E-4;
    Matrix *resultMin = [Matrix matrixOfRows:1 columns:1];
    Matrix *resultMax = [Matrix matrixOfRows:1 columns:1];
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
    trainer.settings[@"C"]                 = @1;
    trainer.settings[@"Hidden Layer Size"] = @900;
    
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:8.0];
}

- (void)testBackPropHousing
{
    YCBackPropTrainer *trainer              = [YCBackPropTrainer trainer];
    trainer.settings[@"Hidden Layer Size"]  = @8;
    trainer.settings[@"L2"]                 = @0.0001;
    trainer.settings[@"Iterations"]         = @1500;
    trainer.settings[@"Alpha"]              = @0.5;
    
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.0];
}

- (void)testRPropHousing
{
    YCRpropTrainer *trainer                 = [YCRpropTrainer trainer];
    trainer.settings[@"Hidden Layer Size"]  = @8;
    trainer.settings[@"L2"]                 = @0.0001;
    trainer.settings[@"Iterations"]         = @200;
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.0];
}

- (void)testStochasticBackPropHousing
{
    YCBackPropTrainer *trainer                 = [YCBackPropTrainer trainer];
    trainer.settings[@"Hidden Layer Size"]  = @8;
    trainer.settings[@"L2"]                 = @1E-5;
    trainer.settings[@"Iterations"]         = @6000;
    trainer.settings[@"Alpha"]              = @0.5;
    trainer.settings[@"Samples"]            = @10;
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.5];
}

- (void)testSVRSMOHousing
{
    YCSMORegressionTrainer *trainer             = [YCSMORegressionTrainer trainer];
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.0];
}

- (void)testRBFHousing
{
    YCOLSTrainer *trainer                = [YCOLSTrainer trainer];
    trainer.settings[@"Kernel Width"]    = @2.8;
    trainer.settings[@"Error Tolerance"] = @0.10;
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.0];
}

- (void)testRBFPRESSHousing
{
    YCOLSTrainer *trainer             = [YCOLSPRESSTrainer trainer];
    trainer.settings[@"Kernel Width"] = @2.8;
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.0];
}

#pragma mark Dataframe Tests

- (void)testCorruptDataframe
{
    YCDataframe *template = [YCDataframe dataframe];
    [template addSampleWithData:@{@"First" : @0.0, @"Second" : @-1.0, @"Third" : @-5.0}];
    [template addSampleWithData:@{@"First" : @6.7, @"Second" :  @0.1, @"Third" : @40.0}];
    YCDataframe *random = [template randomSamplesWithCount:5000];
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

#pragma mark Utility Functions

- (void)testWithTrainer:(YCSupervisedTrainer *)trainer
                                dataset:(NSString *)dataset
                 dependentVariableLabel:(NSString *)label
                                   rmse:(double)rmse
{
    YCDataframe *input    = [self dataframeWithCSVName:dataset];
    YCDataframe *output   = [YCDataframe dataframeWithDictionary:@{label : [input allValuesForAttribute:label]}];
    [input removeAttributeWithIdentifier:label];
    NSDictionary *results = [[YCkFoldValidation validationWithSettings:nil] test:trainer
                                                                           input:input
                                                                          output:output];
    double RMSE           = [results[@"RMSE"] doubleValue];
    
    CleanLog(@"RMSE (CV): %f", RMSE);
    XCTAssertLessThan(RMSE, rmse, @"RMSE above threshold");
}

- (YCDataframe *)dataframeWithCSVName:(NSString *)path
{
    YCDataframe *output    = [YCDataframe dataframe];
    NSBundle *bundle       = [NSBundle bundleForClass:[self class]];
    NSString *filePath     = [bundle pathForResource:path ofType:@"csv"];
    NSString* fileContents = [NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    NSMutableArray *rows = [[fileContents CSVComponents] mutableCopy];
    
    NSArray *labels        = rows[0];
    [rows removeObjectAtIndex:0];
    
    for (NSArray *sampleData in rows)
    {
        [output addSampleWithData:[NSDictionary dictionaryWithObjects:sampleData forKeys:labels]];
    }

    return output;
}

@end
