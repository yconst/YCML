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

- (void)testELMHousing
{
    // Simple training + testing, no cross-validation
    Matrix *trainingData   = [self matrixWithCSVName:@"housing" removeFirst:YES];
    [trainingData shuffleColumns];
    Matrix *trainingOutput = [trainingData getRow:13];
    Matrix *trainingInput  = [trainingData removeRow:13];
    YCELMTrainer *trainer    = [YCELMTrainer trainer];
    trainer.settings[@"C"]   = @8;
    trainer.settings[@"Hidden Layer Size"] = @1000;
    
    YCFFN *model = (YCFFN *)[trainer train:nil
                               inputMatrix:trainingInput
                              outputMatrix:trainingOutput];
    
    Matrix *predictedOutput = [model activateWithMatrix:trainingInput];
    
    [predictedOutput subtract:trainingOutput];
    [predictedOutput elementWiseMultiply:predictedOutput];
    double RMSE = sqrt( (1.0/[predictedOutput count]) * [predictedOutput sum] );
    CleanLog(@"RMSE: %f", RMSE);
    XCTAssertLessThan(RMSE, 4.0, @"RMSE above threshold");
}

- (void)testELMHousingCV
{
    // Simple training + cross-validation
    Matrix *trainingData   = [self matrixWithCSVName:@"housing" removeFirst:YES];
    [trainingData shuffleColumns];
    Matrix *cvData         = [trainingData matrixWithColumnsInRange:NSMakeRange(trainingData.columns - 30, 29)];
    trainingData             = [trainingData matrixWithColumnsInRange:NSMakeRange(0, trainingData.columns - 30)];
    Matrix *trainingOutput = [trainingData getRow:13];
    Matrix *trainingInput  = [trainingData removeRow:13];
    Matrix *cvOutput       = [cvData getRow:13];
    Matrix *cvInput        = [cvData removeRow:13];
    YCELMTrainer *trainer    = [YCELMTrainer trainer];
    trainer.settings[@"C"]   = @8;
    trainer.settings[@"Hidden Layer Size"] = @1000;
    
    YCFFN *model = (YCFFN *)[trainer train:nil
                               inputMatrix:trainingInput
                              outputMatrix:trainingOutput];
    
    Matrix *predictedOutput = [model activateWithMatrix:cvInput];
    
    [predictedOutput subtract:cvOutput];
    [predictedOutput elementWiseMultiply:predictedOutput];
    double RMSE = sqrt( (1.0/[predictedOutput count]) * [predictedOutput sum] );
    CleanLog(@"RMSE: %f", RMSE);
    XCTAssertLessThan(RMSE, 6.0, @"RMSE above threshold");
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
