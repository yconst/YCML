//
//  YCRegressionMetrics.h
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 2/3/15.
//  Copyright (c) 2015 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

// This is a file implementing various metrics to evaluate regression performance.
// The functions can evaluate single attribute as well as multi attribute datasets
// by taking the mean of the values associated with each attribute.
// Both YCDataframe as well as Matrix objects are acceptable as parameters. In the
// latter case, each matrix column is considered as a sample.

@import Foundation;
@class YCDataframe;

double MSE(id trueData, id predictedData);

double RSquared(id trueData, id predictedData);