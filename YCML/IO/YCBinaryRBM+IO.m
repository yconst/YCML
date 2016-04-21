//
//  YCBinaryRBM+IO.m
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

#import "YCBinaryRBM+IO.h"

@implementation YCBinaryRBM (IO)

#pragma mark Text Description

- (NSString *)textDescription
{
    NSMutableString *description = (NSMutableString *)[super textDescription];
    
    // Print RBF function type
    [description appendFormat:@"\nFunction is Sigmoid\n"];
    
    // Print centers
    [description appendFormat:@"\nWeights (%d x %d)\n%@",self.weights.rows,
     self.weights.columns, self.weights];
    
    // Print bandwidths
    [description appendFormat:@"\nVisible Biases (%d x %d)\n%@",self.visibleBiases.rows,
     self.visibleBiases.columns, self.visibleBiases];
    
    // Print output weights
    [description appendFormat:@"\nHidden Biases (%d x %d)\n%@",self.hiddenBiases.rows,
     self.hiddenBiases.columns, self.hiddenBiases];
    
    return description;
}

@end
