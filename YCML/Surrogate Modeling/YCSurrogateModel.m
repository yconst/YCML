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
{
    YCSupervisedModel *_model;
    Matrix *_modesCache;
    Matrix *_parameterBoundsCache;
    BOOL _maximize;
}

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

- (Matrix *)modes
{
    if (!_modesCache)
    {
        _modesCache = [Matrix matrixOfRows:self.objectiveCount columns:1];
        for (int i=0, j=self.objectiveCount; i<j; i++)
        {
            [_modesCache i:i j:0 set:self.maximize ? 1 : 0];
        }
    }
    return _modesCache;
}

- (Matrix *)parameterBounds
{
    if (!_parameterBoundsCache)
    {
        NSArray *order = self.model.properties[@"InputConversionArray"];
        NSDictionary *inputMinValues = self.model.properties[@"InputMinValues"];
        NSDictionary *inputMaxValues = self.model.properties[@"InputMaxValues"];
        Matrix *inputMinMatrix = [Matrix matrixFromNSArray:[self dictionary:inputMinValues
                                                        toArrayWithKeyOrder:order]
                                                      rows:self.model.inputSize
                                                   columns:1];
        Matrix *inputMaxMatrix = [Matrix matrixFromNSArray:[self dictionary:inputMaxValues
                                                        toArrayWithKeyOrder:order]
                                                      rows:self.model.inputSize
                                                   columns:1];
        _parameterBoundsCache = [Matrix matrixFromColumns:@[inputMinMatrix, inputMaxMatrix]];
    }
    return _parameterBoundsCache;
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

- (YCEvaluationMode)supportedEvaluationMode
{
    // Models should be able to predict multiple examples in one pass
    return YCProvidesParallelImplementation;
}

#pragma mark Accessors

- (YCSupervisedModel *)model
{
    return _model;
}

- (void)setModel:(YCSupervisedModel *)model
{
    _model = model;
    _parameterBoundsCache = nil;
}

- (BOOL)maximize
{
    return _maximize;
}

- (void)setMaximize:(BOOL)maximize
{
    _maximize = maximize;
    _modesCache = nil;
}

@end
