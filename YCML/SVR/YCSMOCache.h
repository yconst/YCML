//
//  YCSMOCache.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 29/1/16.
//  Copyright (c) 2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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
#import "YCLinkedList.h"
@class Matrix;

typedef enum cacheStatus { notIncluded, included } cacheStatus;

@interface YCSMOCache : NSObject

- (instancetype)initWithDatasetSize:(NSUInteger)datasetSize cacheSize:(NSUInteger)cacheSize;

- (cacheStatus)queryI:(NSUInteger)i j:(NSUInteger)j;

- (double)getI:(NSUInteger)i j:(NSUInteger)j tickle:(BOOL)tickle;

- (void)setI:(NSUInteger)i j:(NSUInteger)j value:(double)value;

///@name Properties

/**
 An array containing indexes in cache of each example in the dataset
 i.e. index[i] == index in cache of example i
 */
@property NSUInteger *index;

/**
 An array containing all indexes in dataset for each cache element
 i.e. inverseIndex[n] == index in dataset of cache element n
 */
@property NSUInteger *inverseIndex;

/**
 The cache values, MxM
 */
@property Matrix *values;

/**
 The LRU nodes
 */
@property LNode *nodes; // LRU nodes

/**
 The order of LRU indexes
 */
@property YCLinkedList *order; // LRU order

/**
 The permanent diagonal kernel cache
 */
@property Matrix *diagonalCache;

@end
