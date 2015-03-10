//
//  YCSupervisedTrainer.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 2/3/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
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

#import "YCSupervisedTrainer.h"
#import "YCSupervisedModel.h"
#import "YCMatrix/YCMatrix.h"

@implementation YCSupervisedTrainer

@synthesize settings;

+ (instancetype)trainer
{
    return [[self alloc] init];
}

+ (Class)modelClass
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

-(id)init
{
    if (self = [super init])
    {
        self.settings = [NSMutableDictionary dictionary];
    }
    return self;
}

- (YCSupervisedModel *)train:(YCSupervisedModel *)model inputMatrix:(YCMatrix *)input outputMatrix:(YCMatrix *)output
{
    self->_shouldStop = false;
    YCSupervisedModel *theModel = model;
    if (!theModel)
    {
        theModel = [[[[self class] modelClass] alloc] init];
    }
    [self performTrainingModel:theModel inputMatrix:input outputMatrix:output];
    return theModel;
}

- (void)performTrainingModel:(YCSupervisedModel *)model
                 inputMatrix:(YCMatrix *)input
                outputMatrix:(YCMatrix *)output
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.settings forKey:@"settings"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        self.settings = [decoder decodeObjectForKey:@"settings"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copied = [[self class] trainer];
    if (copied)
    {
        [copied setSettings:[self.settings mutableCopy]];
    }
    return copied;
}

- (void)stop
{
    self->_shouldStop = true;
}

@end
