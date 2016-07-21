//
//  YCSMOCache.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 29/1/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCSMOCache.h"
@import YCMatrix;

typedef struct node
{
    struct LIST_NODE *next, *prev;
    void *data;
} node;

@implementation YCSMOCache
{
    unsigned int _size;
}

- (instancetype)init
{
    return [self initWithSize:10];
}

- (instancetype)initWithSize:(NSUInteger)size
{
    self = [super init];
    if (self)
    {
        self.index = [Matrix matrixOfRows:(int)size columns:1];
        self.inverseIndex = [Matrix matrixOfRows:(int)size columns:1];
        self.values = [Matrix matrixOfRows:(int)size columns:1];
        self.status = [Matrix matrixOfRows:(int)size columns:1];
        self.nodes = malloc(sizeof(LNode) * size);
        self.order = [[YCLinkedList alloc] init];
    }
    return self;
}

- (cacheStatus)queryI:(int)i j:(int)j
{
    unsigned ci = [self.index i:i j:0];
    unsigned cj = [self.index i:j j:0];
    
    if (i == j || ci >= _size || cj >= _size)
    {
        return notReserved;
    }

    if (cj > ci) {
        unsigned swap = cj;
        cj = ci;
        ci = swap;
    }
    
    return [self.status i:ci-1 j:cj];
}

- (double)getI:(int)i j:(int)j tickle:(BOOL)tickle
{
    unsigned ci = [self.index i:i j:0];
    unsigned cj = [self.index i:j j:0];
    if (cj > ci)
    {
        unsigned swap = cj;
        cj = ci;
        ci = swap;
    }
    
    // Here also check if node->next exists, if not it is already last.
    if (tickle)
    {
        [self.order removeNode:&self.nodes[ci]];
        [self.order pushNodeBack:&self.nodes[ci]];
        [self.order removeNode:&self.nodes[cj]];
        [self.order pushNodeBack:&self.nodes[cj]];
    }
    return [self.values i:ci-1 j:cj];
}

- (double)setI:(int)i j:(int)j value:(double)value
{
    return 0; // not yet implemented
}

- (void)dealloc
{
    free(self.nodes);
}

@end
