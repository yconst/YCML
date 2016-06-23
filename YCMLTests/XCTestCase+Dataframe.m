//
//  XCTestCase+Dataframe.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 21/4/16.
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

#import "XCTestCase+Dataframe.h"
@import YCML;
@import YCMatrix;
#import "CHCSVParser.h"

// Convenience logging function (without date/object)
#define CleanLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@implementation XCTestCase (Dataframe)

#pragma mark - Utility Functions

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
        // The provided dataframes should be made up of NSNumbers.
        // Thus we need t convert anything coming from the CSV file to NSNumber.
        NSMutableArray *dataAsNumbers = [NSMutableArray array];
        for (id record in sampleData)
        {
            [dataAsNumbers addObject:@([record doubleValue])];
        }
        [output addSampleWithData:[NSDictionary dictionaryWithObjects:dataAsNumbers forKeys:labels]];
    }
    
    return output;
}

@end
