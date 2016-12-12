//
//  YCkNNTrainer.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 6/12/16.
//  Copyright © 2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

#import "YCKPMTrainer.h"
#import "YCKPM.h"

@implementation YCKPMTrainer

+ (Class)modelClass
{
    return [YCKPM class];
}

- (void)performTrainingModel:(YCKPM *)model
                 inputMatrix:(Matrix *)input
                outputMatrix:(Matrix *)output
{
    YCDomain domain = YCMakeDomain(-1, 1);
    Matrix *inputTransform  = [input rowWiseMapToDomain:domain basis:MinMax];
    Matrix *outputTransform = [output rowWiseMapToDomain:domain basis:MinMax];
    Matrix *invOutTransform = [output rowWiseInverseMapFromDomain:domain basis:MinMax];
    Matrix *scaledInput     = [input matrixByRowWiseMapUsing:inputTransform];
    Matrix *scaledOutput    = [output matrixByRowWiseMapUsing:outputTransform];
    
    model.inputTransform = inputTransform;
    model.outputTransform = invOutTransform;
    
    model.prototypes = scaledInput;
    model.targets = scaledOutput;
}

@end
