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

// References for this document:
// https://gist.github.com/justinmstuart/6687145

#import "YCDataframe.h"
#import "YCMissingValue.h"
#import "NSArray+Statistics.h"

@implementation YCDataframe
{
    NSNumberFormatter *f;
}

+ (instancetype)dataframe
{
    return [[self alloc] init];
}

+ (instancetype)dataframeWithDictionary:(NSDictionary *)input
{
    return [self dataframeWithDictionary:input deepCopy:YES];
}

+ (instancetype)dataframeWithDictionary:(NSDictionary *)input deepCopy:(BOOL)copy
{
    YCDataframe *output = [[self alloc] init];
    for (NSString *attributeLabel in [input allKeys])
    {
        NSArray *values = input[attributeLabel];
        if (values)
        {
            [output addAttributeWithIdentifier:attributeLabel data:input[attributeLabel] deepCopy:copy];
        }
        else
        {
            [output addBlankAttributeWithIdentifier:attributeLabel];
        }
        
    }
    return output;
}

// Optional override when subclassing
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _data = [NSMutableDictionary dictionary];
        _attributeTypes = [NSMutableDictionary dictionary];
        f = [[NSNumberFormatter alloc] init];
        [f setAllowsFloats:YES];
    }
    return self;
}

- (NSUInteger)attributeCount
{
    return [_data count];
}

- (NSArray *)allValuesForAttribute:(NSString *)attribute
{
    if (!_data[attribute]) return nil;
    id valueData = [NSKeyedArchiver archivedDataWithRootObject:_data[attribute]];
    return [NSKeyedUnarchiver unarchiveObjectWithData:valueData];
}

- (id)valueOfAttribute:(NSString *)attribute index:(NSUInteger)idx
{
    return [[_data objectForKey:attribute] objectAtIndex:idx];
}

- (void)setValue:(id)val attribute:(NSString *)attribute index:(NSUInteger)idx
{
    [[_data objectForKey:attribute] setObject:val atIndex:idx];
}

- (NSDictionary *)sampleAtIndex:(NSUInteger)idx
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:[self attributeCount]];
    for (id key in _data)
    {
        [ret setValue:_data[key][idx] forKey:key];
    }
    return ret;
}

- (NSArray *)samplesAtIndexes:(NSIndexSet *)idxs
{
    NSUInteger attributeCount = [self attributeCount];
    NSMutableArray *ret = [NSMutableArray array];
    [idxs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *record = [NSMutableDictionary dictionaryWithCapacity:attributeCount];
        for (NSString *feature in _data)
        {
            [record setObject:_data[feature][idx] forKey:feature];
        }
        [ret addObject:record];
    }];
    return ret;
}

- (NSArray *)samplesNotInIndexes:(NSIndexSet *)idxs
{
    NSMutableIndexSet *inverse = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self dataCount])];
    [inverse removeIndexes:idxs];
    return [self samplesAtIndexes:inverse];
}

- (NSArray *)attributeIdentifiers
{
    return [self->_data allKeys];
}

- (NSArray *)classesForAttribute:(NSString *)attribute
{
    NSAssert([self.attributeTypes[attribute] intValue] == Nominal, @"Attributes should be nominal");
    return [[NSMutableSet setWithArray:_data[attribute]] allObjects];
}

- (void)addBlankAttributeWithIdentifier:(NSString *)ident
{
    [self addAttributeWithIdentifier:ident data:nil];
}

- (void)addAttributeWithIdentifier:(NSString *)ident data:(NSArray *)data
{
    [self addAttributeWithIdentifier:ident data:data deepCopy:YES];
}

// Optional override when subclassing
- (void)addAttributeWithIdentifier:(NSString *)ident data:(NSArray *)data deepCopy:(BOOL)copy
{
    if ([[_data objectForKey:ident] isKindOfClass:[NSArray class]]) return;
    
    NSUInteger dataCount = self.dataCount;
    if (data)
    {
        NSAssert(![self attributeCount] || [data count] == dataCount, @"Attribute count differs");
        if (copy || ![data isKindOfClass:[NSMutableArray class]])
        {
            NSMutableArray *copiedArray = [NSMutableArray arrayWithCapacity:dataCount];
            for (id sampleValue in data)
            {
                [copiedArray addObject:[self correctValueFor:sampleValue
                                       AdjustTypeOfAttribute:ident]];
            }
            [_data setObject:copiedArray forKey:ident];
        }
        else
        {
            [_data setObject:data forKey:ident];
            [self autoDetectTypeForAttribute:ident];
        }
    }
    else
    {
        NSMutableArray *newDataArray = [NSMutableArray arrayWithCapacity:dataCount];
        for (int i=0; i<dataCount; i++)
        {
            [newDataArray addObject:[YCMissingValue missingValue]];
        }
        [_data setValue:newDataArray forKey:ident];
    }
    
    if ([_attributeTypes objectForKey:ident]) return;
    
    [_attributeTypes setObject:@0 forKey:ident];
}

// Optional override when subclassing
- (void)removeAttributeWithIdentifier:(NSString *)ident
{
    [_attributeTypes removeObjectForKey:ident];
    [_data removeObjectForKey:ident];
}

// Optional override when subclassing
- (void)renameAttribute:(NSString *)oldIdentifier to:(NSString *)newIdentifier
{
    if ([oldIdentifier isEqualToString:newIdentifier]) return;
    self->_data[newIdentifier] = self->_data[oldIdentifier];
    [self->_data removeObjectForKey:oldIdentifier];
}

- (void)autoDetectTypeForAttribute:(NSString *)ident
{
    NSNumber *currentType = @0;
    NSArray *attributeData = _data[ident];
    if (!ident) return;
    
    for (id value in attributeData)
    {
        if ([value isKindOfClass:[NSString class]])
        {
            NSNumber *numValue = [f numberFromString:value];
            if (!numValue)
            {
                currentType = @1;
                break;
            }
        }
    }
    _attributeTypes[ident] = currentType;
}

- (void)autoDetectTypes
{
    for (NSString *attr in [self->_data allKeys])
    {
        [self autoDetectTypeForAttribute:attr];
    }
}

- (void)addSampleWithData:(NSDictionary *)data
{
    [self insertSampleWithData:data atIndex:MAX([self dataCount], 0)];
}

- (void)addSamplesWithData:(NSArray *)data
{
    [self insertSamplesWithData:data atIndex:MAX([self dataCount], 0)];
}

- (void)insertSampleWithData:(NSDictionary *)data atIndex:(NSUInteger)idx
{
    NSDictionary *sample = data ? data : [NSDictionary dictionary];
    [self insertSamplesWithData:@[sample] atIndex:idx];
}

// Optional override when subclassing
- (void)insertSamplesWithData:(NSArray *)data atIndex:(NSUInteger)idx
{
    for (NSDictionary *record in [data reverseObjectEnumerator])
    {
        for (id key in record)
        {
            id oldValue = [_data objectForKey:key];
            if (!oldValue)
            {
                [self addBlankAttributeWithIdentifier:key];
            }
        }
        for (id key in _data)
        {
            id sampleValue = [record objectForKey:key];
            if (sampleValue)
            {
                [_data[key] insertObject:[self correctValueFor:sampleValue AdjustTypeOfAttribute:key]
                                 atIndex:idx];
            }
            else
            {
                [_data[key] insertObject:[YCMissingValue missingValue] atIndex:idx];
            }
        }
    }
}

- (NSMutableDictionary *)removeSampleAtIndex:(NSUInteger)idx
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    for (id key in _data)
    {
        NSNumber *val = [[_data objectForKey:key] objectAtIndex:idx];
        [ret setValue:val forKey:key];
        [[_data objectForKey:key] removeObjectAtIndex:idx];
    }
    return ret;
}

- (void)removeSamplesAtIndexes:(NSIndexSet *)idxs
{
    for (NSMutableArray *feature in [_data allValues])
    {
        [feature removeObjectsAtIndexes:idxs];
    }
}

- (void)removeAllSamples
{
    for (NSMutableArray *a in [_data allValues])
    {
        [a removeAllObjects];
    }
}

- (void)appendDataframe:(YCDataframe *)dataframe
{
    for (NSString *identifier in [dataframe attributeKeys])
    {
        [self addAttributeWithIdentifier:identifier data:nil deepCopy:NO];
    }
    for (NSString *identifier in [dataframe attributeKeys])
    {
        self->_data[identifier] = [[dataframe allValuesForAttribute:identifier] mutableCopy];
    }
}

- (NSDictionary *)stats
{
    NSMutableDictionary *stats = [NSMutableDictionary dictionary];
    for (NSString *attribute in [_data allKeys])
    {
        if ([self.attributeTypes[attribute] intValue] != Ordinal) continue;
        [stats setObject:[self statsForAttribute:attribute] forKey:attribute];
    }
    return stats;
}

- (NSDictionary *)stat:(NSString *)stat
{
    NSMutableDictionary *stats = [NSMutableDictionary dictionary];
    for (NSString *attribute in [_data allKeys])
    {
        if ([self.attributeTypes[attribute] intValue] != Ordinal) continue;
        [stats setObject:[self stat: stat forAttribute:attribute] forKey:attribute];
    }
    return stats;
}

- (NSDictionary *)statsForAttribute:(NSString *)attribute
{
    return [_data[attribute] stats];
}

- (NSNumber *)stat:(NSString *)stat forAttribute:(NSString *)attribute
{
    NSAssert([_attributeTypes[attribute] intValue] == Ordinal, @"Attribute should be ordinal");
    return [_data[attribute] calculateStat:stat];
}

#pragma  mark Property Accessors

- (NSArray *)allSamples
{
    NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self dataCount])];
    return [self samplesAtIndexes:set];
}

- (NSArray *)allSampleValues
{
    NSMutableArray *allSamples = [NSMutableArray array];
    NSArray *allKeys = [self attributeKeys];
    NSUInteger count = [self dataCount];
    for (int i=0; i<count; i++)
    {
        [allSamples addObject:[NSMutableArray array]];
    }
    for (NSString *key in allKeys)
    {
        NSArray *attribute = self->_data[key];
        for (int i=0; i<count; i++)
        {
            [allSamples[i] addObject:attribute[i]];
        }
    }
    [allSamples insertObject:allKeys atIndex:0];
    return allSamples;
}

- (NSMutableDictionary *)allData
{
    return _data;
}

- (NSUInteger)dataCount
{
    if ([_data count] == 0) return 0;
    return [[[_data allValues] objectAtIndex:0] count];
}

- (NSArray *)attributeKeys
{
    return [[self->_data allKeys] copy];
}

#pragma mark value getter/setter Overrides

- (id)valueForUndefinedKey:(NSString *)aKey
{
    for (id key in self.attributeKeys)
    {
        if ([key isEqualToString:aKey])
        {
            return [self allValuesForAttribute:key];
        }
    }
    return [super valueForUndefinedKey:aKey];
}

- (void)setValue:(id)value forKey:(NSString *)aKey
{
    if ([value isKindOfClass:[NSArray class]])
    {
        for (id key in self.attributeKeys)
        {
            if ([key isEqualToString:aKey])
            {
                [self addAttributeWithIdentifier:aKey data:value];
                return;
            }
        }
    }
    [super setValue:value forUndefinedKey:aKey];
}

#pragma mark NSCoding Implementation

// Optional override when subclassing
- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:_data forKey:@"data"];
    [encoder encodeObject:_attributeTypes forKey:@"attributeTypes"];
}

// Optional override when subclassing
- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super init]) {
        _data = [decoder decodeObjectForKey:@"data"];
        _attributeTypes = [decoder decodeObjectForKey:@"attributeTypes"];
    }
    return self;
}

#pragma mark NSCopying Implementation

// Optional override when subclassing
- (instancetype)copyWithZone:(NSZone *)zone
{
    YCDataframe *cp = [[[self class] allocWithZone:zone] init];
    cp->_data = [NSMutableDictionary dictionaryWithCapacity:[self->_data count]];
    for (NSString *ident in [_data allKeys])
    {
        cp->_data[ident] = [_data[ident] mutableCopyWithZone:zone];
    }
    cp->_attributeTypes = [_attributeTypes mutableCopyWithZone:zone];
    return cp;
}

#pragma mark Shallow Copying

// Optional override when subclassing
- (instancetype)shallowCopy
{
    YCDataframe *scp = [[[self class] alloc] init];
    scp->_data = _data;
    scp->_attributeTypes = _attributeTypes;
    return scp;
}

- (instancetype)shallowCopyWithAttributesOfType:(AttributeType)type
{
    YCDataframe *scp = [[self class] dataframe];
    for (NSString *attributeLabel in [self.attributeTypes allKeys])
    {
        if ([self.attributeTypes[attributeLabel] intValue] == type)
        {
            [scp addAttributeWithIdentifier:attributeLabel
                                       data:self->_data[attributeLabel]
                                   deepCopy:NO];
        }
    }
    return scp;
}

#pragma mark Description

- (NSString *)description
{
    NSString *s = [NSString stringWithFormat:
                   @"%@ with %ld attributes and %ld samples.\nAttribute Order:\n",
            NSStringFromClass([self class]),
            [self attributeCount],
            self.dataCount];
    int c = 1;
    for (NSString *attributeName in [self->_data allKeys])
    {
        s = [s stringByAppendingFormat:@"%d.\t%@\n", c, attributeName];
        c++;
    }
    return s;
}

#pragma mark Helpers

- (id)correctValueFor:(id)value AdjustTypeOfAttribute:(NSString *)ident
{
    if ([value isKindOfClass:[NSNumber class]])
    {
        if (!_attributeTypes[ident]) [_attributeTypes setObject:@0 forKey:ident];
        return value;
    }
    if ([value isKindOfClass:[NSString class]])
    {
        NSNumber *numValue = [f numberFromString:value];
        if (numValue)
        {
            return numValue;
        }
    }
    if ([_attributeTypes[ident] isEqual: @0]) [_attributeTypes setObject:@1 forKey:ident];
    return value;
}

@end

