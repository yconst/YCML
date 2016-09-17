//
//  YCSMOCache.m
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

#import "YCSMOCache.h"
@import YCMatrix;

typedef struct node
{
    struct LIST_NODE *next, *prev;
    void *data;
} node;

@implementation YCSMOCache
{
    unsigned _datasetSize;
    unsigned _cacheSize;
}

static unsigned notFound = UINT_MAX;

- (instancetype)initWithDatasetSize:(NSUInteger)datasetSize cacheSize:(NSUInteger)cacheSize
{
    self = [super init];
    if (self)
    {
        self.index = malloc(sizeof(unsigned) * datasetSize);
        self.inverseIndex = malloc(sizeof(unsigned) * cacheSize);
        self.values = [Matrix matrixOfRows:(int)cacheSize columns:(int)cacheSize]; // -1
        self.nodes = malloc(sizeof(LNode) * cacheSize);
        self.order = [[YCLinkedList alloc] init];
        
        for (int i = 0; i < datasetSize; i++)
        {
            self.index[i] = notFound;
        }
        
        
        for (int i = 0; i < cacheSize; i++)
        {
            self.inverseIndex[i] = notFound;
            
            LNode *node = &self.nodes[i];
            node->obj = &self.inverseIndex[i];
            
            [self.order pushTail:&self.nodes[i]];
        }
        
        self.diagonalCache = [Matrix matrixOfRows:(int)datasetSize columns:1 value:DBL_MAX];
        
        _datasetSize = (unsigned)datasetSize;
        _cacheSize = (unsigned)cacheSize;
    }
    return self;
}

- (cacheStatus)queryI:(int)i j:(int)j
{
    if (i == j)
    {
        return [self.diagonalCache i:i j:0] == DBL_MAX ? notIncluded : included;
    }
    
    unsigned ci = self.index[i];
    unsigned cj = self.index[j];
    
    if (ci == notFound || cj == notFound)
    {
        return notIncluded;
    }

    return included;
}

- (double)getI:(int)i j:(int)j tickle:(BOOL)tickle
{
    if (i == j)
    {
        return [self.diagonalCache i:i j:0];
    }
    
    unsigned ci = self.index[i];
    unsigned cj = self.index[j];
    
    if (cj > ci)
    {
        unsigned swap = cj;
        cj = ci;
        ci = swap;
    }
    
    // Here also check if node->next exists, if not it is already last.
    if (tickle)
    {
        [self.order pop:&self.nodes[ci]];
        [self.order pushTail:&self.nodes[ci]];
        [self.order pop:&self.nodes[cj]];
        [self.order pushTail:&self.nodes[cj]];
    }
    return [self.values i:ci j:cj]; // -1
}

- (void)setI:(int)i j:(int)j value:(double)value
{
    if (i == j)
    {
        [self.diagonalCache i:i j:0 set:value];
        return;
    }
    
    unsigned ci, cj;
    
    if (self.index[i] == notFound)
    {
        // index[i] does not exist in the cache
        LNode *node = [self.order popHead];
        
        // ci is the offset from inverseindex pointed by node->obj
        ci = (unsigned) (((unsigned *)node->obj) - self.inverseIndex);
        
        // ci is now the location in the cache that is to be overwritten (LRU)
        for (int k = 0; k < ci; k++)
        {
            [self.values i:ci j:k set:0]; // -1
        }
        
        if (self.inverseIndex[ci] != notFound) self.index[self.inverseIndex[ci]] = notFound;
        
        self.index[i] = ci;
        self.inverseIndex[ci] = i;
        [self.order pushTail:node];
    }
    else
    {
        ci = self.index[i];
        [self.order pop:&self.nodes[ci]];
        [self.order pushTail:&self.nodes[ci]];
    }
    
    if (self.index[j] == notFound)
    {
        // index[j] does not exist in the cache
        LNode *node = [self.order popHead];
        
        cj = (unsigned) (((unsigned *)node->obj) - self.inverseIndex);
        
        // cj is now the location in the cache that is to be overwritten (LRU)
        for (int k = 0; k < cj; k++)
        {
            [self.values i:cj j:k set:0]; // -1
        }
        
        if (self.inverseIndex[cj] != notFound) self.index[self.inverseIndex[cj]] = notFound;
        
        self.index[j] = cj;
        self.inverseIndex[cj] = j;
        [self.order pushTail:node];
    }
    else
    {
        cj = self.index[j];
        [self.order pop:&self.nodes[cj]];
        [self.order pushTail:&self.nodes[cj]];
    }
    
    // ci and cj now refer to the cache entries that should be written
    
    if (cj > ci)
    {
        unsigned swap = cj;
        cj = ci;
        ci = swap;
    }
    
    [self.values i:ci j:cj set:value]; // -1
}

- (void)dealloc
{
    free(self.nodes);
}

@end
