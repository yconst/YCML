//
//  YCSurrogateModel.m
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

#import "YCSurrogateModel.h"
@import YCMatrix;

@implementation YCSurrogateModel

- (int)objectiveCount
{
    return self.model.outputSize;
}

- (int)parameterCount
{
    return self.model.inputSize;
}

- (int)constraintCount
{
    return 0;
}

- (Matrix *)parameterBounds
{
    NSArray *order = self.model.properties[@"InputConversionArray"];
    NSDictionary *inputMinValues = self.model.properties[@"InputMinValues"];
    NSDictionary *inputMaxValues = self.model.properties[@"InputMaxValues"];
    Matrix *inputMinMatrix = [Matrix matrixFromNSArray:[self dictionary:inputMinValues
                                                    toArrayWithKeyOrder:order]
                                                  Rows:self.model.inputSize
                                               Columns:1];
    Matrix *inputMaxMatrix = [Matrix matrixFromNSArray:[self dictionary:inputMaxValues
                                                    toArrayWithKeyOrder:order]
                                                  Rows:self.model.inputSize
                                               Columns:1];
    Matrix *bounds = [Matrix matrixFromColumns:@[inputMinMatrix, inputMaxMatrix]];
    return bounds;
}

- (Matrix *)initialValuesRangeHint
{
    return [self parameterBounds];
}

- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters
{
    Matrix *output = [self.model activateWithMatrix:parameters];
    [target copyValuesFrom:output];
}

- (NSArray *)parameterLabels
{
    return self.model.properties[@"InputConversionArray"];
}

- (NSArray *)objectiveLabels
{
    return self.model.properties[@"OutputConversionArray"];
}

- (NSArray *)constraintLabels
{
    return nil;
}

- (NSArray *)dictionary:(NSDictionary *)dictionary toArrayWithKeyOrder:(NSArray *)order
{
    NSMutableArray *output = [NSMutableArray array];
    for (id key in order)
    {
        if (dictionary[key])
        {
            [output addObject:dictionary[key]];
        }
    }
    return output;
}

@end
