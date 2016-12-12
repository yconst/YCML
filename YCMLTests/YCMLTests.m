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
#import "XCTestCase+Dataframe.h"
#import "YCSMOCache.h"

// Convenience logging function (without date/object)
#define CleanLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface YCMLTests : XCTestCase

@end

@implementation YCMLTests

#pragma mark - FeedForward Net Tests

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
    Matrix *params = [Matrix uniformRandomLowerBound:lo upperBound:hi];
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
    Matrix *params = [Matrix uniformRandomLowerBound:lo upperBound:hi];
    
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

#pragma mark - SMO Cache Tests

- (void)testLinkedList
{
    int count = 50;
    LNode *nodes = malloc(sizeof(LNode) * count);
    YCLinkedList *list = [[YCLinkedList alloc] init];
    
    for (int i=0; i<count; i++)
    {
        if (arc4random_uniform(100) > 50)
        {
            [list pushTail:&nodes[i]];
        }
        else
        {
            [list pushHead:&nodes[i]];
        }
        
    }
    
    for (int i=0; i<count; i++)
    {
        LNode *node;
        if (arc4random_uniform(100) > 50)
        {
            node = [list popHead];
        }
        else
        {
            node = [list popTail];
        }
        XCTAssert(node->headSide == nil, @"Headside not nil");
        XCTAssert(node->tailSide == nil, @"Tailside not nil");
        if (list.count>0)
        {
            XCTAssert(list.headNode->headSide == nil, @"Head node's Headside not nil");
            XCTAssert(list.tailNode->tailSide == nil, @"Tail node's Tailside not nil");
        }
    }
    
    XCTAssertEqual(list.count, 0, @"Count is incorrect");
}

- (void)testSMOCacheStore
{
    YCSMOCache *cache = [[YCSMOCache alloc] initWithDatasetSize:100 cacheSize:20];
    
    // Non-diagonal
    XCTAssertEqual([cache queryI:2 j:5], notIncluded, @"Cache status query error");
    
    double reference = 7.5;
    [cache setI:2 j:5 value:reference];
    double test = [cache getI:2 j:5 tickle:YES];
    
    XCTAssertEqual(reference, test, @"Retrieved value not equal to reference");
    
    XCTAssertEqual([cache queryI:2 j:5], included, @"Cache status query error");
    
    reference = 1.2;
    [cache setI:3 j:5 value:reference];
    test = [cache getI:3 j:5 tickle:YES];
    
    XCTAssertEqual(reference, test, @"Retrieved value not equal to reference");
    
    XCTAssertEqual([cache queryI:3 j:5], included, @"Cache status query error");
    
    // Diagonal
    reference = 1.6;
    [cache setI:3 j:3 value:reference];
    test = [cache getI:3 j:3 tickle:YES];
    
    XCTAssertEqual(reference, test, @"Retrieved value not equal to reference");
    
    XCTAssertEqual([cache queryI:3 j:3], included, @"Cache status query error");
    
    // Store several entries
    for (int c=0; c<500; c++)
    {
        int i = arc4random_uniform(100);
        int j = arc4random_uniform(100);
        double value = ((double)arc4random() / 0x100000000);
        
        [cache setI:i j:j value:value];
    }
    
    int count = 18;
    Matrix *locations = [Matrix uniformRandomRows:2 columns:count domain:YCMakeDomain(0, count)];
    
    for (int c=0; c<count; c++)
    {
        int i = (int)[locations i:0 j:c];
        int j = (int)[locations i:1 j:c];
        
        [cache setI:i j:j value:i*j];
    }
    
    for (int c=0; c<count; c++)
    {
        int i = (int)[locations i:0 j:c];
        int j = (int)[locations i:1 j:c];
        
        if ([cache queryI:i j:j] == included)
        {
            XCTAssertEqual([cache getI:i j:j tickle:YES], i*j,
                           @"Retrieved value not equal to reference");
            
        }
    }
    
    locations = [Matrix uniformRandomRows:2 columns:count domain:YCMakeDomain(0, count)];
    
    for (int c=0; c<count; c++)
    {
        int i = (int)[locations i:0 j:c];
        int j = (int)[locations i:1 j:c];
        
        [cache setI:i j:j value:i*j];
    }
    
    for (int c=0; c<count; c++)
    {
        int i = (int)[locations i:0 j:c];
        int j = (int)[locations i:1 j:c];
        
        if ([cache queryI:i j:j] == included)
        {
            XCTAssertEqual([cache getI:i j:j tickle:YES], i*j,
                           @"Retrieved value not equal to reference");
            
        }
    }
}

- (void)testSMOCacheQuery
{
    YCSMOCache *cache = [[YCSMOCache alloc] initWithDatasetSize:100 cacheSize:10];
    [cache setI:2 j:4 value:1];
    [cache setI:3 j:5 value:1];
    
    // The following are included
    XCTAssertTrue([cache queryI:2 j:4]);
    XCTAssertTrue([cache queryI:3 j:5]);
    XCTAssertTrue([cache queryI:4 j:2]);
    XCTAssertTrue([cache queryI:5 j:3]);
    
    // The following are not included
    XCTAssertFalse([cache queryI:2 j:5]);
    XCTAssertFalse([cache queryI:5 j:2]);
    XCTAssertFalse([cache queryI:3 j:4]);
    XCTAssertFalse([cache queryI:4 j:3]);
    XCTAssertFalse([cache queryI:2 j:2]);
    XCTAssertFalse([cache queryI:3 j:3]);
    XCTAssertFalse([cache queryI:4 j:4]);
    XCTAssertFalse([cache queryI:5 j:5]);
}

- (void)testKernelCaching
{
    int inputSize = 100;
    int sequenceSize = 10000;
    int repetitions = 500;
    int cacheSize = 30;
    Matrix *input = [Matrix uniformRandomRows:25 columns:inputSize domain:YCMakeDomain(0, 1)];
    Matrix *sequence = [Matrix uniformRandomRows:3 columns:sequenceSize domain:YCMakeDomain(0, inputSize)];
    
    YCSVR *model = [YCSVR model];
    
    // Calculate the kernel values using the model's kernel
    for (int i=0; i<sequenceSize; i++)
    {
        unsigned a = (unsigned)[sequence i:0 j:i];
        unsigned b = (unsigned)[sequence i:1 j:i];
        double value = [[model.kernel kernelValueForA:[input column:a] b:[input column:b]] i:0 j:0];
        [sequence i:2 j:i set:value];
    }
    
    // Calculate the kernel values using the trainer mechanism
    YCSMORegressionTrainer *trainer = [YCSMORegressionTrainer trainer];
    trainer.cache = [[YCSMOCache alloc] initWithDatasetSize:inputSize cacheSize:cacheSize];
    
    for (int i=0; i<sequenceSize; i++)
    {
        unsigned a = (unsigned)[sequence i:0 j:i];
        unsigned b = (unsigned)[sequence i:1 j:i];
        double value = [sequence i:2 j:i];
        double test = [trainer kernelValueForA:a B:b input:input
                                         model:model tickle:NO replace:NO];
        XCTAssertEqual(value, test, @"Values not equal");
    }
    
    // Repeat store-retrieve of small batches of kernel calculations
    sequenceSize = 15;
    sequence = [Matrix uniformRandomRows:3 columns:sequenceSize domain:YCMakeDomain(0, inputSize)];
    
    for (int r=0; r<repetitions; r++)
    {
        for (int i=0; i<sequenceSize; i++)
        {
            unsigned a = (unsigned)[sequence i:0 j:i];
            unsigned b = (unsigned)[sequence i:1 j:i];
            double value = [[model.kernel kernelValueForA:[input column:a] b:[input column:b]] i:0 j:0];
            [sequence i:2 j:i set:value];
        }
        
        for (int k=0; k<20; k++)
        {
            for (int i=0; i<sequenceSize; i++)
            {
                unsigned a = (unsigned)[sequence i:0 j:i];
                unsigned b = (unsigned)[sequence i:1 j:i];
                double value = [sequence i:2 j:i];
                double test = [trainer kernelValueForA:a B:b input:input
                                                 model:model tickle:YES replace:YES];
                double cacheResult = [trainer.cache getI:a j:b tickle:NO];
                XCTAssertEqual(value, test, @"Values not equal");
                XCTAssertEqual(cacheResult, test, @"Values not equal");
            }
        }
    }
}

#pragma mark - SMO Tests

- (void)testRBFKernel
{
    YCRBFKernel *kernel = [[YCRBFKernel alloc] init];
    kernel.properties[@"Beta"] = @10;
    
    Matrix *a = [Matrix matrixFromNSArray:@[@1, @2,
                                            @5, @-1,
                                            @9, @-5] rows:3 columns:2];
    Matrix *b = [Matrix matrixFromNSArray:@[@5, @-4, @-3, @2, @1,
                                            @6, @-5, @-4, @-8, @1,
                                            @-4, @3, @8, @-2, @9] rows:3 columns:5];
    Matrix *r = [kernel kernelValueForA:a b:b];
    NSLog(@"%@",r);
    
    a = [Matrix matrixFromNSArray:@[@1,
                                    @5,
                                    @9] rows:3 columns:1];
    b = [Matrix matrixFromNSArray:@[@5,
                                    @6,
                                    @-4] rows:3 columns:1];
    Matrix *r00 = [kernel kernelValueForA:a b:b];
    NSLog(@"%@", r00);
    XCTAssertEqual([r i:0 j:0], [r00 i:0 j:0]);
    
    a = [Matrix matrixFromNSArray:@[@2,
                                    @-1,
                                    @-5] rows:3 columns:1];
    Matrix *r10 = [kernel kernelValueForA:a b:b];
    NSLog(@"%@", r10);
    XCTAssertEqual([r i:1 j:0], [r10 i:0 j:0]);
    
    b = [Matrix matrixFromNSArray:@[@-3,
                                    @-4,
                                    @8] rows:3 columns:1];
    Matrix *r12 = [kernel kernelValueForA:a b:b];
    NSLog(@"%@", r12);
    XCTAssertEqual([r i:1 j:2], [r12 i:0 j:0]);
    
    b = [Matrix matrixFromNSArray:@[@1,
                                      @1,
                                      @9] rows:3 columns:1];
    Matrix *r14 = [kernel kernelValueForA:a b:b];
    NSLog(@"%@", r14);
    XCTAssertEqual([r i:1 j:4], [r14 i:0 j:0]);
}

- (void)testSVMAndSMOOutput
{
    YCSVR *model         = [YCSVR model];
    model.kernel         = [[YCLinearKernel alloc] init];
    Matrix *input        = [Matrix matrixFromNSArray:@[@1, @0, @1,
                                                       @1, @0, @1,
                                                       @1, @1, @0] rows:3 columns:3];
    Matrix *l            = [Matrix matrixFromNSArray:@[@0.1, @-0.3, @1.0] rows:1 columns:3];
    Matrix *lastModified = [Matrix matrixOfRows:1 columns:4 value:-1];
    
    YCSMORegressionTrainer *trainer = [YCSMORegressionTrainer trainer];
    double y = [trainer outputForModel:model input:input lambdas:l previousOutputs:nil
                          lastModified:lastModified exampleIndex:1 bias:0.5 tickleCache:NO];
    XCTAssertEqualWithAccuracy(0.3, y, 1E-8);
    
    model.sv = input;
    model.lambda = l;
    model.b = 0.5;
    
    y = [[model activateWithMatrix:input] i:0 j:1];
    XCTAssertEqualWithAccuracy(0.3, y, 1E-8);
}

- (void)testSMOStep
{
    YCSVR *model         = [YCSVR model];
    model.kernel         = [[YCLinearKernel alloc] init];
    Matrix *input        = [Matrix matrixFromNSArray:@[@1, @0, @1, @0,
                                                       @1, @1, @0, @0] rows:2 columns:4];
    Matrix *output       = [Matrix matrixFromNSArray:@[@1, @0, @0, @-1] rows:1 columns:4];
    Matrix *lambdas      = [Matrix matrixFromNSArray:@[@0, @0, @0, @0] rows:1 columns:4];
    
    YCSMORegressionTrainer *trainer = [YCSMORegressionTrainer trainer];
    trainer.settings[@"Disable Cache"] = @YES;
    
    double bias = 0.0;
    
    for (int i=0; i<50; i++)
    {
        int i1 = arc4random_uniform(4);
        int i2 = arc4random_uniform(4);
        
        [trainer step:model input:input output:output lambdas:lambdas previousOutputs:nil
         lastModified:nil i1:i1 i2:i2 bias:&bias epsilon:0.1 C:1.0 tickleCache:NO];
    }
    
    NSLog(@"Lambdas:%@, bias:%f", lambdas, bias);
    
    model.lambda = lambdas;
    model.sv = input;
    model.b = bias;
    
    Matrix *check = [Matrix matrixFromNSArray:@[@1, @0,
                                                @1, @1] rows:2 columns:2];
    
    Matrix *prediction = [model activateWithMatrix:check];
    
    XCTAssertGreaterThan([prediction i:0 j:0], 0.59, @"Prediction outside margin");
    XCTAssertLessThan([prediction i:0 j:1], 0.31, @"Prediction outside margin");
    NSLog(@"%@", prediction);
}

#pragma mark - Cross-Validation Tests

- (void)testLinearModel
{
    YCLinRegTrainer *trainer = [YCLinRegTrainer trainer];
    trainer.settings[@"L2"]                = @0.001;
    trainer.settings[@"Iterations"]        = @10000;
    trainer.settings[@"Alpha"]             = @0.5;
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:8.0];
}

- (void)testKPM
{
    YCKPMTrainer *trainer = [YCKPMTrainer trainer];
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:8.0];
}

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

- (void)testLinearSVRSMOHousing
{
    YCSMORegressionTrainer *trainer         = [YCSMORegressionTrainer trainer];
    trainer.settings[@"Disable Cache"] = @YES;
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.0];
}

- (void)testRBFSVRSMOHousing
{
    YCSMORegressionTrainer *trainer         = [YCSMORegressionTrainer trainer];
    trainer.settings[@"Kernel"]             = @"RBF";
    trainer.settings[@"C"]                  = @0.5;
    trainer.settings[@"Beta"]               = @1.4;
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.0];
}

- (void)testRBFNetOLSHousing
{
    YCOLSTrainer *trainer                   = [YCOLSTrainer trainer];
    trainer.settings[@"Kernel Width"]       = @2.8;
    trainer.settings[@"Error Tolerance"]    = @0.10;
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.0];
}

- (void)testRBFNetOLSPRESSHousing
{
    YCOLSTrainer *trainer             = [YCOLSPRESSTrainer trainer];
    trainer.settings[@"Kernel Width"] = @2.8;
    [self testWithTrainer:trainer dataset:@"housing" dependentVariableLabel:@"MedV" rmse:6.0];
}



@end
