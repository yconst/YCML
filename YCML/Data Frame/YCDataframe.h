//
//  YCDataframe.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 29/3/15.
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

@import Foundation;
@class YCMutableArray, OrderedDictionary, MutableOrderedDictionary;

typedef enum AttributeType : int16_t {
    Ordinal = 0, // Numerical
    Nominal = 1, // Categorical
    Interval = 2
} AttributeType;

@interface YCDataframe : NSObject <NSCoding, NSCopying>
{
    @protected MutableOrderedDictionary *_data;
}

+ (instancetype)dataframe;

+ (instancetype)dataframeWithDictionary:(NSDictionary *)input;

+ (instancetype)dataframeWithDictionary:(NSDictionary *)input deepCopy:(BOOL)copy;

- (YCDataframe *)dataframeByFilteringAttributes:(NSArray *)attributes;

- (NSUInteger)attributeCount;

- (YCMutableArray *)arrayReferenceForAttribute:(NSString *)attribute;

- (NSArray *)allValuesForAttribute:(NSString *)attribute;

- (id)valueOfAttribute:(NSString *)attribute index:(NSUInteger)idx;

- (void)setValue:(id)val attribute:(NSString *)attribute index:(NSUInteger)idx;

- (OrderedDictionary *)sampleAtIndex:(NSUInteger)idx;

- (NSArray *)samplesAtIndexes:(NSIndexSet *)idxs;

- (NSArray *)samplesNotInIndexes:(NSIndexSet *)idxs;

- (void)sortByAttribute:(NSString *)attribute ascending:(BOOL)ascending;

- (NSArray *)classesForAttribute:(NSString *)attribute; // TODO: add max label count

- (void)addBlankAttributeWithIdentifier:(NSString *)ident;

- (void)addAttributeWithIdentifier:(NSString *)ident data:(NSArray *)data;

- (void)addAttributeWithIdentifier:(NSString *)ident data:(NSArray *)data deepCopy:(BOOL)copy;

- (void)removeAttributeWithIdentifier:(NSString *)ident;

- (void)renameAttribute:(NSString *)oldIdentifier to:(NSString *)newIdentifier;

- (void)autoDetectTypeForAttribute:(NSString *)ident;

- (void)autoDetectTypes;

- (void)addSampleWithData:(NSDictionary *)data;

- (void)addSamplesWithData:(NSArray *)data;

- (void)insertSampleWithData:(NSDictionary *)data atIndex:(NSUInteger)idx;

- (void)insertSamplesWithData:(NSArray *)data atIndex:(NSUInteger)idx;

- (void)replaceSampleAtIndex:(NSUInteger)idx withData:(NSDictionary *)data;

- (NSMutableDictionary *)removeSampleAtIndex:(NSUInteger)idx;

- (void)removeSamplesAtIndexes:(NSIndexSet *)idxs;

- (void)removeAllSamples;

- (void)appendDataframe:(YCDataframe *)dataframe;

- (instancetype)shallowCopy;

- (instancetype)shallowCopyWithAttributesOfType:(AttributeType)type;

- (OrderedDictionary *)stats;

- (OrderedDictionary *)stat:(NSString *)stat;

- (NSDictionary *)statsForAttribute:(NSString *)attribute;

- (NSNumber *)stat:(NSString *)stat forAttribute:(NSString *)attribute;

- (NSDictionary *)outlierIndexesWithFenceMultiplier:(double)multiplier;

- (YCDataframe *)uniques;

/**
 Returns an NSArray of NSDictionaries, each corresponding to a sample.
 */
@property (readonly) NSArray *allSamples;

/**
 Returns an NSArray of NSArrays, each corresponding to a sample. The first array
 contains the attribute labels.
 
 @warning The first NSArray contains the attribute labels.
 */
@property (readonly) NSArray *allSampleValues;

@property (readonly) NSUInteger dataCount;

@property NSMutableDictionary *attributeTypes;

@property (readonly) NSArray *attributeKeys;

@property (readonly) NSNumberFormatter *numberFormatter;

@end
