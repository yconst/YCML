//
//  YCProblem.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 19/3/15.
//  Copyright (c) 2015-2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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
@class Matrix;

/*
 With respect to concurrency, there are three ways in which a
 problem function can be evaluated:
 
 1. The function needs to be evaluated sequentially
 2. The function can be evaluated concurrently, but it's implementation is sequential
 3. The function itself provides an (optimized) parallel implementation
 
 The latter case is the most favorable, as the problem may provide an optimized
 parallel implementation that supersedes the performance of mere concurrent evaluation.
 
 */
typedef NS_ENUM(int, YCEvaluationMode) {
    YCRequiresSequentialEvaluation = 0,
    YCSupportsConcurrentEvaluation = 1,
    YCProvidesParallelImplementation = 2
};

typedef NS_ENUM(int, YCObjectiveTarget) {
    YCObjectiveMinimize = 0,
    YCObjectiveMaximize = 1
};

@protocol YCProblem

- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters;

@property (readonly) Matrix *parameterBounds;

@property (readonly) Matrix *initialValuesRangeHint;

@property (readonly) int parameterCount;

@property (readonly) int objectiveCount;

@property (readonly) int constraintCount;

@property (readonly) Matrix *modes;

@property (readonly) YCEvaluationMode supportedEvaluationMode;

@optional

@property (readonly) NSArray *parameterLabels;

@property (readonly) NSArray *objectiveLabels;

@property (readonly) NSArray *constraintLabels;

@end
