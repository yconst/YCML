//
//  YCProblem.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 19/3/15.
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
#import "YCGradientDescent.h"
#import "YCDerivativeProblem.h"

@implementation YCGradientDescent

- (instancetype)initWithProblem:(NSObject<YCProblem> *)aProblem settings:(NSDictionary *)settings
{
    self = [super initWithProblem:aProblem settings:settings];
    if (self)
    {
        self.settings[@"Alpha"] = @0.001;
    }
    return self;
}

- (BOOL)iterate:(int)iteration
{
    BOOL maximize = [self.problem.modes i:0 j:0] > 0;
    int k = self.problem.parameterCount;
    
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
        self.state[@"gradients"] = [Matrix matrixOfRows:k columns:1];
    }
    else
    {
        Matrix *values = self.state[@"values"];
        Matrix *gradients = self.state[@"gradients"];
        double alpha = [self.settings[@"Alpha"] doubleValue];
        [(NSObject<YCDerivativeProblem> *)self.problem derivatives:gradients parameters:values];
        [gradients multiplyWithScalar:alpha];
        if (maximize)
        {
            [values add:gradients];
        }
        else
        {
            [values subtract:gradients];
        }
    }
    
    if (self.settings[@"Target"])
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

@end
