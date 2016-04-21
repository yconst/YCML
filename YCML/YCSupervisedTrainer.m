//
//  YCSupervisedTrainer.m
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

#import "YCSupervisedTrainer.h"
#import "YCSupervisedModel.h"
#import "YCDataframe.h"
#import "YCDataframe+Matrix.h"
@import YCMatrix;

@implementation YCSupervisedTrainer

- (YCSupervisedModel *)train:(YCSupervisedModel *)model
                       input:(YCDataframe *)input
                      output:(YCDataframe *)output
{
    YCSupervisedModel *theModel = model;
    if (!theModel)
    {
        theModel = [[[[self class] modelClass] alloc] init];
    }
    theModel.properties[@"InputMinValues"]        = [input stat:@"min"];
    theModel.properties[@"InputMaxValues"]        = [input stat:@"max"];
    theModel.properties[@"OutputMinValues"]       = [output stat:@"min"];
    theModel.properties[@"OutputMaxValues"]       = [output stat:@"max"];
    theModel.properties[@"InputConversionArray"]  = [input conversionArray];
    theModel.properties[@"OutputConversionArray"] = [output conversionArray];
    [theModel.trainingSettings addEntriesFromDictionary:self.settings];
    Matrix *inputM = [input getMatrixUsingConversionArray:theModel.properties[@"InputConversionArray"]];
    Matrix *outputM = [output getMatrixUsingConversionArray:theModel.properties[@"OutputConversionArray"]];
    [self train:theModel inputMatrix:inputM outputMatrix:outputM];
    return self.shouldStop ? nil : theModel;
}

- (YCSupervisedModel *)train:(YCSupervisedModel *)model inputMatrix:(Matrix *)input outputMatrix:(Matrix *)output
{
    self.shouldStop = NO;
    YCSupervisedModel *theModel = model;
    if (!theModel)
    {
        theModel = [[[[self class] modelClass] alloc] init];
    }
    [self performTrainingModel:theModel inputMatrix:input outputMatrix:output];
    return self.shouldStop ? nil : theModel;
}

- (void)performTrainingModel:(YCSupervisedModel *)model
                 inputMatrix:(Matrix *)input
                outputMatrix:(Matrix *)output
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

@end
