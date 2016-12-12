//
//  YCMutableArray.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 18/4/16.
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
