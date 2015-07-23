//
//  YCNSGAII.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 3/8/14.
//  Copyright (c) 2014 Ioannis Chatzikonstantinou. All rights reserved.
//

#import "YCOptimizer.h"
#import "YCPopulationBasedOptimizer.h"
#import "YCIndividual.h"

@interface YCNSGAII : YCPopulationBasedOptimizer

@end

@interface YCNSGAIndividual : YCIndividual

@property int rank;

@property double crowdingDistance;

@property int n;

@property NSMutableSet *s;

@end

@interface NSMutableArray (Shuffling)

- (void)shuffle;

@end