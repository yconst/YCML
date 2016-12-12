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

/**
 Requests a problem function evaluation from the receiver
 
 @param target: The target for the objective function and constraint values.
 First all objective function values, then constraints.
 @param parameters: The decision variable values for which to evaluate
 */
- (void)evaluate:(Matrix *)target parameters:(Matrix *)parameters;

/**
 The numerical bounds for the decision variables
 */
@property (readonly) Matrix *parameterBounds;

/**
 Optional array correponding to initial value ranges
 */
@property (readonly) Matrix *initialValuesRangeHint;

/**
 The number of decision variables
 */
@property (readonly) int parameterCount;

/**
 The number of objectives
 */
@property (readonly) int objectiveCount;

/**
 The number of constraints
 */
@property (readonly) int constraintCount;

/**
 A matrix denoting targets for optimization, per objective: Minimization or Maximization
 */
@property (readonly) Matrix *modes;

/**
 A value showing how the receiver treats cases where more than one solutions
 needs to be evaluated. The receiver may return the following values:
 i. YCRequiresSequentialEvaluation: the receiver requires that solutions are
 presented sequentially for evaluation
 ii. YCSupportsConcurrentEvaluation: the receiver allows concurrent evaluation 
 of more than one solutions
 iii. YCProvidesParallelImplementation: the receiver provides its own
 evaluation implementation and solutions should be presented all at once, as
 part of a single matrix
 */
@property (readonly) YCEvaluationMode supportedEvaluationMode;

@optional

/**
 Labels associated with decision variables
 */
@property (readonly) NSArray *parameterLabels;

/**
 Labels associated with objectives
 */
@property (readonly) NSArray *objectiveLabels;

/**
 Labels associated with constraints
 */
@property (readonly) NSArray *constraintLabels;

/**
 Additional properties associated with the last set of solution(s)
 TODO: This should be implemented as an array instead of dictionary
 */
@property (readonly) NSDictionary *metaProperties;

@end
