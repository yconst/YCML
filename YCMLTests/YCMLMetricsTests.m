//
//  TCMLMetricsTests.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 6/10/15.
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

@import XCTest;
@import YCML;
@import YCMatrix;

// Convenience logging function (without date/object)
#define CleanLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface YCMLMetricsTests : XCTestCase

@end

@implementation YCMLMetricsTests

- (void)testRSquared
{
    Matrix *groundTruth = [Matrix matrixFromNSArray:@[@10, @0, @5, @20, @3, @17, @12, @8, @0, @15] rows:1 columns:10];
    double r2 = RSquared(groundTruth, groundTruth);
    XCTAssert(r2 == 1, "Identical Predictor R2 != 1");
    CleanLog(@"Identical Predictor: %f", r2);
    
    Matrix *prediction = [Matrix matrixFromNSArray:@[@9, @1, @5, @18, @3, @13, @13, @9, @1, @14] rows:1 columns:10];
    r2 = RSquared(groundTruth, prediction);
    XCTAssert(r2 > 0.9, "Good Predictor R2 < 0.9");
    CleanLog(@"Good Predictor: %f", r2);
    
    prediction = [Matrix matrixOfRows:1 columns:10 value:[groundTruth meansOfRows]->matrix[0]];
    r2 = RSquared(groundTruth, prediction);
    XCTAssert(r2 == 0, "Mean Predictor R2 != 0");
    CleanLog(@"Mean Predictor: %f", r2);
    
    prediction = [Matrix uniformRandomRows:1 columns:10 domain:YCMakeDomain(0, 20)];
    r2 = RSquared(groundTruth, prediction);
    CleanLog(@"Uniform Random Predictor: %f", r2);
    
    prediction = [Matrix matrixFromNSArray:@[@19, @0, @15, @4, @3, @2, @19, @1, @7, @12] rows:1 columns:10];
    r2 = RSquared(groundTruth, prediction);
    CleanLog(@"Bad Predictor: %f", r2);
    
    Matrix *rand1 = [Matrix uniformRandomRows:1 columns:10 domain:YCMakeDomain(0, 1)];
    Matrix *rand2 = [Matrix uniformRandomRows:1 columns:10 domain:YCMakeDomain(0, 1)];
    
    double r2_2 = RSquared(rand1, rand2);
    CleanLog(@"Uni Random Ground Truth / Uni Random Predictor: %f", r2_2);
}

@end
