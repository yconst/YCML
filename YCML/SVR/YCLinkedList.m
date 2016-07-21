//
//  YCLinkedList.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 11/12/15.
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

// Adapted from CKLinkedList https://github.com/mschettler/CKLinkedList

#import "YCLinkedList.h"

LNode * LNodeMake(id obj, LNode *next, LNode *prev);    // convenience method for creating a LNode

@implementation YCLinkedList

- (id)init
{
    if ((self = [super init]) == nil) return nil;

    first = last = nil;
    size = 0;

    return self;
}

+ (id)listWithObject:(id)anObject
{
    YCLinkedList *n = [[YCLinkedList alloc] initWithObject:anObject];
    return n;
}

- (id)initWithObject:(id)anObject
{
    if ((self = [super init]) == nil) return nil;

    LNode *n = LNodeMake(anObject, nil, nil);

    first = last = n;
    size = 1;

    return self;
}

- (void)pushBack:(id)anObject
{
    if (anObject == nil) return;

    LNode *n = LNodeMake(anObject, nil, last);

    if (size == 0)
    {
        first = last = n;
    }
    else
    {
        last->next = n;
        last = n;
    }
    size++;
}

- (id)lastObject
{
    return last ? last->obj : nil;
}

- (id)firstObject
{
    return first ? first->obj : nil;
}

- (LNode *)firstNode
{
    return first;
}

- (LNode *)lastNode
{
    return last;
}

- (void)pushFront:(id)anObject
{
    if (anObject == nil) return;

    LNode *n = LNodeMake(anObject, first, nil);

    if (size == 0) {
        first = last = n;
    } else {
        first->prev = n;
        first = n;
    }
    size++;
}

- (void)insertObject:(id)anObject beforeNode:(LNode *)node
{
    [self insertObject:anObject betweenNode:node->prev andNode:node];
}

- (void)insertObject:(id)anObject afterNode:(LNode *)node
{
    [self insertObject:anObject betweenNode:node andNode:node->next];
}

- (void)insertObject:(id)anObject betweenNode:(LNode *)previousNode andNode:(LNode *)nextNode
{
    if (anObject == nil) return;

    LNode *n = LNodeMake(anObject, nextNode, previousNode);

    if (previousNode)
    {
        previousNode->next = n;
    }
    else
    {
        first = n;
    }

    if (nextNode)
    {
        nextNode->prev = n;
    }
    else
    {
        last = n;
    }
    size++;
}

- (void)pushNodeBack:(LNode *)n
{
    if (size == 0) {
        first = last = LNodeMake(n->obj, nil, nil);
    } else {
        last->next = LNodeMake(n->obj, nil, last);
        last = last->next;
    }

    size++;
}

- (void)pushNodeFront:(LNode *)n
{
    if (size == 0) {
        first = last = LNodeMake(n->obj, nil, nil);
    } else {
        first->prev = LNodeMake(n->obj, first, nil);
        first = first->prev;
    }

    size++;
}

// With support for negative indexing!
- (id)objectAtIndex:(const int)inidx
{
    int idx = inidx;

    // they've given us a negative index
    // we just need to convert it positive
    if (inidx < 0) idx = size + inidx;

    if (idx >= size || idx < 0) return nil;

    LNode *n = nil;

    if (idx > (size / 2)) {
        // loop from the back
        int curridx = size - 1;
        for (n = last; idx < curridx; --curridx) n = n->prev;
        return n->obj;
    } else {
        // loop from the front
        int curridx = 0;
        for (n = first; curridx < idx; ++curridx) n = n->next;
        return n->obj;
    }

    return nil;
}


- (id)popBack
{
    if (size == 0) return nil;

    id ret = last->obj;
    [self removeNode:last];
    return ret;
}

- (id)popFront
{
    if (size == 0) return nil;

    id ret = first->obj;
    [self removeNode:first];
    return ret;
}

- (void)removeNode:(LNode *)aNode
{
    if (size == 0) return;

    if (size == 1)
    {
        // delete first and only
        first = last = nil;
    }
    else if (aNode->prev == nil)
    {
        // delete first of many
        first = first->next;
        first->prev = nil;
    }
    else if (aNode->next == nil)
    {
        // delete last
        last = last->prev;
        last->next = nil;
    }
    else
    {
        // delete in the middle
        LNode *tmp = aNode->prev;
        tmp->next = aNode->next;
        tmp = aNode->next;
        tmp->prev = aNode->prev;
    }
    aNode->obj = nil;
    free(aNode);
    size--;
}

- (BOOL)removeObjectEqualTo:(id)anObject
{
    LNode *n = nil;

    for (n = first; n; n=n->next)
    {
        if (n->obj == anObject)
        {
            [self removeNode:n];
            return YES;
        }
    }
    return NO;
}

- (void)removeAllObjects
{
    LNode *n = first;

    while (n) {
        LNode *next = n->next;
        n->obj = nil;
        free(n);
        n = next;
    }

    first = last = nil;
    size = 0;
}

- (NSUInteger)count
{
    return size;
}

- (BOOL)containsObject:(id)anObject
{
    LNode *n = nil;

    for (n = first; n; n=n->next) {
        if (n->obj == anObject) return YES;
    }

    return NO;
}

- (NSArray *)allObjects
{
    NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:size];
    LNode *n = nil;

    for (n = first; n; n=n->next)
    {
        [ret addObject:n->obj];
    }
    return [NSArray arrayWithArray:ret];
}

- (NSArray *)allObjectsReverse
{
    NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:size];
    LNode *n = nil;

    for (n = last; n; n=n->prev)
    {
        [ret addObject:n->obj];
    }
    return [NSArray arrayWithArray:ret];
}

- (void)dealloc
{
    [self removeAllObjects];
}

@end

LNode * LNodeMake(id obj, LNode *next, LNode *prev)
{
    LNode *n = malloc(sizeof(LNode));
    n->next = next;
    n->prev = prev;
    n->obj = obj;
    return n;
};



