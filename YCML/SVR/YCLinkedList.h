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

@import Foundation;

typedef struct LNode LNode;

struct LNode
{
    NSUInteger index;
    LNode *headSide;
    LNode *tailSide;
};

/**
 A linked list implementation
 
 @warning: This list does not memory manage it's members at all!
 */
@interface YCLinkedList : NSObject
{
    LNode *head;
    LNode *tail;
    NSUInteger size;
}

- (void)pushTail:(LNode *)n;           // adds a node object to the end of the list

- (void)pushHead:(LNode *)n;           // adds a node object to the beginning of the list

- (void *)pop:(LNode *)aNode;       // remove and return a given node

- (void *)popTail;                     // pops a node object from the end of the list

- (void *)popHead;                     // pops a node object from the beginning of the list

///@ Properties

@property (readonly) LNode *headNode;

@property (readonly) LNode *tailNode;

@property (readonly) NSUInteger count;

@end
