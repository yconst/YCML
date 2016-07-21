//
//  YCRBFNet+IO.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 20/4/16.
//  Copyright © 2016 (Yannis) Chatzikonstantinou. All rights reserved.
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

#import "YCRBFNet+IO.h"

@implementation YCRBFNet (IO)

#pragma mark - NSCopying Implementation

- (instancetype)copyWithZone:(NSZone *)zone
{
    YCRBFNet *copy = [super copyWithZone:zone];
    if (copy)
    {
        copy.centers = [self.centers copy];
        copy.widths = [self.widths copy];
        copy.weights = [self.weights copy];
        copy.inputTransform = [self.inputTransform copy];
        copy.outputTransform = [self.outputTransform copy];
    }
    return copy;
}

#pragma mark - NSCoding Implementation

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.centers = [aDecoder decodeObjectForKey:@"centers"];
        self.widths = [aDecoder decodeObjectForKey:@"widths"];
        self.weights = [aDecoder decodeObjectForKey:@"weights"];
        self.inputTransform = [aDecoder decodeObjectForKey:@"inputTransform"];
        self.outputTransform = [aDecoder decodeObjectForKey:@"outputTransform"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.centers forKey:@"centers"];
    [aCoder encodeObject:self.widths forKey:@"widths"];
    [aCoder encodeObject:self.weights forKey:@"weights"];
    [aCoder encodeObject:self.inputTransform forKey:@"inputTransform"];
    [aCoder encodeObject:self.outputTransform forKey:@"outputTransform"];
}

#pragma mark - Text Description

- (NSString *)textDescription
{
    NSMutableString *description = (NSMutableString *)[super textDescription];
    
    // Print RBF function type
    [description appendFormat:@"\nRBF Function is Gaussian\n"];
    
    // Print input and output transform matrices
    if (self.inputTransform)
    {
        [description appendFormat:@"\nInput Transform (%d x %d)\nMapping Function: y = c1*x + c2\n%@",self.inputTransform.rows,
         self.inputTransform.columns, self.inputTransform];
    }
    if (self.outputTransform)
    {
        [description appendFormat:@"\nOutput Transform (%d x %d)\nMapping Function: y = c1*x + c2\n%@",self.outputTransform.rows,
         self.outputTransform.columns, self.outputTransform];
    }
    
    // Print centers
    [description appendFormat:@"\nCenters (%d x %d)\n%@",self.centers.rows,
     self.centers.columns, self.centers];
    
    // Print bandwidths
    [description appendFormat:@"\nBandwidths (%d x %d)\n%@",self.widths.rows,
     self.widths.columns, self.widths];
    
    // Print output weights
    [description appendFormat:@"\nOutput Weights (%d x %d)\n%@",self.weights.rows,
     self.weights.columns, self.weights];
    
    return description;
}

#pragma mark - PMML Export
#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))

- (void)PMMLEncodeWithRootElement:(NSXMLElement *)root
{
    
}
#endif

@end
