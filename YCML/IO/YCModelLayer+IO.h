//
//  YCModelLayer+IO.h
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

#import <YCML/YCML.h>

@interface YCModelLayer (IO) <NSCopying, NSCoding>

/**
 Produces a human-readable text description of the receiver.
 
 @param model The model that owns the receiving layer.
 @param index The index of the layer in the network.
 
 @return The text description of the receiving layer.
 */
- (NSString *)textDescriptionWithModel:(YCFFN *)model layerIndex:(NSUInteger)index;

#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))
/**
 Encodes information of the receiver, given a model and a target XML element.
 To be overridden when subclassing.
 
 @param target The XML Element corresponding to the model.
 @param model The model that owns the receiving layer.
 @param index The index of the layer in the network.
 
 @warning This method is only available on MacOS platforms.
 */
- (void)PMMLEncodeWithTargetElement:(NSXMLElement *)target
                              model:(YCFFN *)model
                         layerIndex:(NSUInteger)index;
#endif

@end
