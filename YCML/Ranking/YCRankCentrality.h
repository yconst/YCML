//
//  YCRankCentrality.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 24/11/16.
//  Copyright © 2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

/**
 RankCentrality
 
 This class implements a mechanism to obtain absolute scores from 
 pair-wise comparisons for a population of individuals. It is based on the 
 paper "Iterative Ranking from Pair-wise Comparisons". It accepts a diagonal nxn matrix
 containing comparison scores for n individuals, and produces a vector (nx1 matrix)
 with values corresponding to each of the n items absolute score.
 */

@interface YCRankCentrality : NSObject

/**
 Calculates the transition matrix for a given matrix containing the number
 of losses for each individual.
 
 @param comparisons: Matrix containing the number
    of losses for each individual. The value in cell at i,j refers to the number
    of times j lost to i. Conversely, the value at j, i refers to the number of
    times i lost to j. Summing these up gives us the total number of matches played.
 
 @return The transition matrix containing the probabilities of the Markov chain
 */
+ (Matrix *)transitionMatrixWithComparisons:(Matrix *)comparisons;

/**
 Calculates the scores of a population of individuals according to the
 Bradley-Terry-Luce model of comparative judgement.
 
 @param transitionMatrix: Matrix containing the probabilities of Markov chain transitions.
 
 @return Vector containing the scores
 */
+ (Matrix *)scoresWithTransitionMatrix:(Matrix *)transitionMatrix;

/**
 Calculates the scores of a population of individuals according to the 
 Bradley-Terry-Luce model of comparative judgement.
 
 @param comparisons: Matrix containing the number
 of losses for each individual. The value in cell at i,j refers to the number
 of times j lost to i. Conversely, the value at j, i refers to the number of
 times i lost to j. Summing these up gives us the total number of matches played.
 
 @return Vector containing the scores
 */
+ (Matrix *)scoresWithComparisons:(Matrix *)comparisons;

@end
