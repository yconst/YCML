//
//  YCMLRankingTests.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 27/11/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import <XCTest/XCTest.h>
@import YCML;
@import YCMatrix;

#define ARC4RANDOM_MAX 0x100000000

@interface YCMLRankingTests : XCTestCase

@end

@implementation YCMLRankingTests

- (void)testRankingNormalized
{
    double comparison_array[9] = {0.0, 0.9, 1.0,  // Beginner
                                  0.1, 0.0, 0.7,  // Advanced
                                  0.0 ,0.3, 0.0}; // Master
    Matrix *comparisons = [Matrix matrixFromArray:comparison_array rows:3 columns:3];
    Matrix *scores = [YCRankCentrality scoresWithComparisons:comparisons];
    NSLog(@"%@", scores);
}

- (void)testRankingUnnormalized
{
    double comparison_array[9] = {0, 9, 15,  // Beginner
                                  3, 0, 7,   // Advanced
                                  1 ,4, 0};  // Master
    Matrix *comparisons = [Matrix matrixFromArray:comparison_array rows:3 columns:3];
    Matrix *scores = [YCRankCentrality scoresWithComparisons:comparisons];
    NSLog(@"%@", scores);
}

- (void)testRankingBinaryBias
{
    double bias = 0.1;
    double comparison_array[9] = {0,    1+bias, 2+bias,  // Beginner
                                  bias, 0,      1+bias,  // Advanced
                                  bias, bias,   0};      // Master
    Matrix *comparisons = [Matrix matrixFromArray:comparison_array rows:3 columns:3];
    Matrix *scores = [YCRankCentrality scoresWithComparisons:comparisons];
    NSLog(@"%@", scores);
}

- (void)testNewMember
{
    double comparison_array[16] = {0.0, 0.9, 1.0, 1.0,  // Beginner
                                  0.1, 0.0, 0.7, 0.0,   // Advanced
                                  0.0 ,0.3, 0.0, 0.0,   // Master
                                  0.0, 1.0, 1.0, 0.0};  // New player
    Matrix *comparisons = [Matrix matrixFromArray:comparison_array rows:4 columns:4];
    Matrix *scores = [YCRankCentrality scoresWithComparisons:comparisons];
    NSLog(@"%@", scores);
}

- (void)testSt
{
    double comparison_array[16] = {0.0, 1.0, 1.0, 0.0,  // Beginner
                                   0.0, 0.0, 1.0, 0.0,   // Advanced
                                   0.0 ,0.0, 0.0, 0.0,   // Master
                                   1.0, 0.0, 0.0, 0.0};  // New player
    Matrix *comparisons = [Matrix matrixFromArray:comparison_array rows:4 columns:4];
    [comparisons incrementAll:1.0];
    Matrix *scores = [YCRankCentrality scoresWithComparisons:comparisons];
    NSLog(@"%@", scores);
}


/**
 Simulation-based experimens for n players of different skill level
 
 In this experiment, our goal is to reclaim the skills matrix
 of n players, by looking at a nxn matrix representing match results
 of m trials between random player pairs. The result of the trials is
 proportional to the players' skill levels, according to the 
 Bradley-Terry-Luce model for comparative judgment. We make use
 of the Rank Centrality algorithm, and compare our normalized results
 with a normalized skills vector, using dot product.
 */
- (void)testSimulation
{
    int playerCount = 10;
    int simulationCount = 10000;
    
    double skills[10] = {10.0, 9.0, 3.4, 5.5, 8.2, 1.2, 9.0, 6.8, 3.1, 9.8};
    Matrix *skillsMatrix = [Matrix matrixFromArray:skills rows:playerCount columns:1];
    
    Matrix *matches = [Matrix matrixOfRows:playerCount columns:playerCount];
    
    for (int i=0; i<simulationCount; i++)
    {
        int a = arc4random_uniform(playerCount);
        int b = arc4random_uniform(playerCount);
        
        if (a==b) continue;
        
        double skillA = [skillsMatrix i:a j:0];
        double skillB = [skillsMatrix i:b j:0];
        double sum = skillA + skillB;
        
        if (sum == 0) continue;
        
        if (((double)arc4random() / ARC4RANDOM_MAX) > skillA/sum)
        {
            [matches i:a j:b increment:1];
        }
    }
    
    Matrix *scores = [YCRankCentrality scoresWithComparisons:matches];
    
    Matrix *skillsNormalized = [skillsMatrix matrixByUnitizing];
    Matrix *scoresNormalized = [scores matrixByUnitizing];
    
    NSAssert([skillsNormalized dotWith:scoresNormalized] > 0.98, @"Skills/scores correlation too low");
    
}

@end
