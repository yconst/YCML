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

@import Foundation;

typedef struct LNode LNode;

struct LNode
{
    __unsafe_unretained id obj;
    LNode *next;
    LNode *prev;
};

@interface YCLinkedList : NSObject
{
    LNode *first;
    LNode *last;
    unsigned int size;
}

+ (id)listWithObject:(id)anObject;          // init the linked list with a single object

- (id)initWithObject:(id)anObject;          // init the linked list with a single object

- (void)pushBack:(id)anObject;              // add an object to back of list

- (void)pushFront:(id)anObject;             // add an object to front of list

- (id)popBack;                              // remove object at end of list (returns it)

- (id)popFront;                             // remove object at front of list (returns it)

- (BOOL)removeObjectEqualTo:(id)anObject;   // removes object equal to anObject, returns (YES) on success

- (void)removeAllObjects;                   // clear out the list

- (BOOL)containsObject:(id)anObject;        // (YES) if passed object is in the list, (NO) otherwise

- (void)pushNodeBack:(LNode *)n;            // adds a node object to the end of the list

- (void)pushNodeFront:(LNode *)n;           // adds a node object to the beginning of the list

- (void)removeNode:(LNode *)aNode;          // remove a given node

- (id)objectAtIndex:(const int)idx;

- (NSArray *)allObjects;

- (NSArray *)allObjectsReverse;

- (void)insertObject:(id)anObject beforeNode:(LNode *)node;

- (void)insertObject:(id)anObject afterNode:(LNode *)node;

///@ Properties

@property (readonly) id firstObject;

@property (readonly) id lastObject;

@property (readonly) LNode *firstNode;

@property (readonly) LNode *lastNode;

@property (readonly) NSUInteger count;

@end
