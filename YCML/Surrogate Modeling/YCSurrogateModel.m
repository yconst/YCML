//
//  YCSurrogateModel.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 5/7/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
//

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
