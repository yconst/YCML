//
//  YCBackPropTrainer.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 21/3/15.
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

@import YCMatrix;
#import "YCRProp.h"
#import "YCDerivativeProblem.h"

@implementation YCRProp

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem settings:(NSDictionary *)settings
{
    self = [super initWithProblem:aProblem settings:settings];
    if (self)
    {
        self.settings[@"etaPlus"]    = @1.2;
        self.settings[@"etaMinus"]   = @0.5;
        self.settings[@"etaMax"]     = @50;
        self.settings[@"etaMin"]     = @1E-6;
        self.settings[@"Iterations"] = @100;
    }
    return self;
}

- (BOOL)iterate:(int)iteration
{
    int k               = self.problem.parameterCount;
    double etaPlus      = [self.settings[@"etaPlus"] doubleValue];
    double etaMinus     = [self.settings[@"etaMinus"] doubleValue];
    double etaMax       = [self.settings[@"etaMax"] doubleValue];
    double etaMin       = [self.settings[@"etaMin"] doubleValue];
    BOOL maximize       = [self.problem.modes i:0 j:0] > 0;
    int direction       = maximize ? 1 : -1;
    
    if (!self.state[@"values"])
    {
        Matrix *newValues = [Matrix matrixOfRows:k columns:1];
        
        Matrix *initialRanges = [self.problem initialValuesRangeHint];
        
        for (int i=0; i<k; i++)
        {
            double start = [initialRanges valueAtRow:i column:0];
            double range = [initialRanges valueAtRow:i column:1] - start;
            [newValues setValue:((double)arc4random() / 0x100000000) * range + start
                            row:i column:0];
        }
        self.state[@"values"] = newValues;
        self.state[@"gradients"]    = [Matrix matrixOfRows:k columns:1];
        self.state[@"oldGradients"] = [Matrix matrixOfRows:k columns:1];
        self.state[@"stepSizes"]    = [Matrix matrixOfRows:k columns:1 value:0.1]; // Rprop suggested
        self.state[@"previousSteps"]= [Matrix matrixOfRows:k columns:1];
    }
    else
    {
        Matrix *values              = self.state[@"values"];
        Matrix *gradients           = self.state[@"oldGradients"]; // We'll use this for writing
        [(NSObject<YCDerivativeProblem> *)self.problem derivatives:gradients parameters:values];
        Matrix *oldGradients        = self.state[@"gradients"];
        self.state[@"gradients"]    = gradients;
        self.state[@"oldGradients"] = oldGradients;
        
        Matrix *dProduct            = [gradients matrixByElementWiseMultiplyWith:oldGradients];
        Matrix *signs = [gradients matrixByApplyingFunction:^double(double value) {
            return value > 0 ? 1 : value == 0 ? 0 : -1;
        }];
        
        Matrix *stepSizes           = self.state[@"stepSizes"];
        Matrix *previousSteps       = self.state[@"previousSteps"];
        
        NSUInteger count = signs.count;
        for (int i=0;i<count;i++)
        {
            if (dProduct->matrix[i] > 0)
            {
                stepSizes->matrix[i] = MIN(stepSizes->matrix[i] * etaPlus, etaMax);
                previousSteps->matrix[i] = direction * signs->matrix[i] * stepSizes->matrix[i];
                values->matrix[i] += previousSteps->matrix[i];
            }
            else if (dProduct->matrix[i] < 0)
            {
                stepSizes->matrix[i] = MAX(stepSizes->matrix[i] * etaMinus, etaMin);
                values->matrix[i] -= previousSteps->matrix[i];
                gradients->matrix[i] = 0; // Artificially set derivative to ZERO ...
            }
            else
            {
                previousSteps->matrix[i] = direction * signs->matrix[i] * stepSizes->matrix[i];
                values->matrix[i] += previousSteps->matrix[i];
            }
        }
    }
    
    if (iteration % 10 == 0 && self.settings[@"Target"])
    {
        Matrix *values = self.state[@"values"];
        double target = [self.settings[@"Target"] doubleValue];
        
        Matrix *objectiveValues = [Matrix matrixOfRows:self.problem.objectiveCount columns:1];
        [self.problem evaluate:objectiveValues parameters:values];
        double best = [objectiveValues sum];
        self.state[@"best"] = @(best);
        if ((maximize && best >= target) || (best <= target)) return NO;
    }
    return YES;
}

- (NSArray *)bestParameters
{
    if (!self.state[@"values"]) return nil;
    return @[self.state[@"values"]];
}

- (NSArray *)bestObjectives
{
    if (!self.state[@"best"]) return nil;
    return @[self.state[@"best"]];
}

- (NSArray *)bestConstraints
{
    return @[@0];
}

@end
