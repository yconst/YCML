//
//  YCLinkedList.m
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

// Adapted from CKLinkedList https://github.com/mschettler/CKLinkedList

// head -- headSide . tailSide -- headSide . tailSide -- tail

#import "YCLinkedList.h"

LNode * LNodeMake(NSUInteger index, LNode *headSide, LNode *tailSide);    // convenience method for creating a LNode

@implementation YCLinkedList

- (id)init
{
    if ((self = [super init]) == nil) return nil;

    head = nil;
    tail = nil;
    size = 0;

    return self;
}

- (LNode *)headNode
{
    return head;
}

- (LNode *)tailNode
{
    return tail;
}

- (void)pushTail:(LNode *)n
{
    NSAssert(n != nil, @"Input cannot be nil");
    if (size == 0)
    {
        head = n;
        tail = n;
        head->headSide = nil;
        tail->tailSide = nil;
    }
    else
    {
        n->tailSide = nil;
        n->headSide = tail;
        tail->tailSide = n;
        tail = n;
    }
    size++;
}

- (void)pushHead:(LNode *)n
{
    NSAssert(n != nil, @"Input cannot be nil");
    if (size == 0)
    {
        head = n;
        tail = n;
        head->headSide = nil;
        tail->tailSide = nil;
    }
    else
    {
        n->headSide = nil;
        n->tailSide = head;
        head->headSide = n;
        head = n;
    }
    size++;
}


- (void *)popTail
{
    return [self pop:tail];
}

- (void *)popHead
{
    return [self pop:head];
}


- (void *)pop:(LNode *)aNode
{
    NSAssert(aNode != nil, @"Input cannot be nil");
    
    if (size == 0) return nil;

    if (aNode == head && aNode == tail)
    {
        // delete first and only
        head = tail = nil;
    }
    else if (aNode == head)
    {
        // delete first
        head = head->tailSide;
        head->headSide = nil;
    }
    else if (aNode == tail)
    {
        // delete last
        tail = tail->headSide;
        tail->tailSide = nil;
    }
    else
    {
        // delete in the middle
        // here of course we cannot be sure that the given
        // node is in fact part of this linked list...
        LNode *tmp = aNode->headSide;
        tmp->tailSide = aNode->tailSide;
        tmp = aNode->tailSide;
        tmp->headSide = aNode->headSide;
    }
    aNode->headSide = nil;
    aNode->tailSide = nil;
    size--;
    return aNode;
}

- (void)removeAllObjects
{
    head = nil;
    tail = nil;
    size = 0;
}

- (NSUInteger)count
{
    return size;
}

- (void)dealloc
{
    [self removeAllObjects];
}

@end

LNode * LNodeMake(NSUInteger index, LNode *headSide, LNode *tailSide)
{
    LNode *n = malloc(sizeof(LNode));
    n->tailSide = tailSide;
    n->headSide = headSide;
    n->index = index;
    return n;
};



