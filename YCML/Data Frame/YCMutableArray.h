//
//  YCMutableArray.h
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 18/4/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

@import Foundation;

@interface Stats : NSObject

- (instancetype)initWithArray:(NSArray *)array;

@property (readonly) double sum;

@property (readonly) double mean;

@property (readonly) double min;

@property (readonly) double max;

@property (readonly) double variance;

@property (readonly) double sd;

@end

@interface YCMutableArray : NSMutableArray

- (NSArray *)sample:(int)samples replacement:(BOOL)replacement;

- (NSIndexSet *)indexesOfOutliersWithFenceMultiplier:(double)multiplier;

- (NSNumber *)quantile:(double)q;

- (YCMutableArray *)bins:(NSUInteger)numberOfBins;

@property (readonly) NSNumber *sum;

@property (readonly) NSNumber *mean;

@property (readonly) NSNumber *min;

@property (readonly) NSNumber *max;

@property (readonly) NSNumber *Q1;

@property (readonly) NSNumber *median;

@property (readonly) NSNumber *Q3;

@property (readonly) NSNumber *variance;

@property (readonly) NSNumber *sd;

@property (readonly) Stats *stats;

@property (readonly) YCMutableArray *bins;

@end
