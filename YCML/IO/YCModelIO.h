//
//  YCModelIO.h
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

#import <Foundation/Foundation.h>

/**
 Describes the methods used to export models to various formats, as well as
 create models from imported data.
 */
@protocol YCModelIO <NSObject, NSCopying, NSCoding>

/// @name Decoding

/**
 Returns a model generated using the PMML-encoded data
 in the supplied string.
 
 @param string The string containing PMML data.
 
 @return The generated model.
 */
+ (YCGenericModel *)modelWithPMMLString:(NSString *)string;

/// @name Encoding

/**
 Encodes information of the receiver, given a root XML element.
 To be overridden when subclassing.
 
 @param root The root XML Element.
 @warning This method is only available on MacOS platforms.
 */
#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))
- (void)PMMLEncodeWithRootElement:(NSXMLElement *)root;
#endif

/**
 Produces a human-readable text description of the model,
 including all of it's properties.
 */
@property (readonly) NSString *textDescription;

/**
 Produces a PMML (https://en.wikipedia.org/wiki/Predictive_Model_Markup_Language)
 file of the model, including all of it's properties.
 
 @warning This property is only available on MacOS platforms.
 */
#if (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))
@property (readonly) NSString *PMMLString;
#endif

@end
