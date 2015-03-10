
#YCML

YCML is a Machine Learning framework in Objective-C (and soon Swift!).
Currently, it only implements the basic Extreme Learning Machines (ELM) algorithm, as 
it is described in [1].

ELMs are Feed-Forward Networks with a single hidden layer. Their hidden layer weights
are initialized randomly, and the output linear weights are determined analytically.

More algorithms soon to follow. 

##Features

- Embedded model input/output normalization facility.
- Generic Supervised Learning base class that can accommodate a variety of algorithms.
- Based on YCMatrix, a matrix library that makes use of the Accelerate Framework.

##Getting started

Import the project in your workspace, or compile the framework
and import. YCML depends on YCMatrix, which has been included as a
Git submodule.

Note: I was planning to use Cocoapods for facilitating deployment, but, to be honest, I had
a really hard time using it the way I would like (e.g. with local Pods etc.).
I found that Cocoapods is riddled with frequent changes that break the API, and render much of 
the information online useless. As such, I decided not to spend more time with it and went with git
submodules.

##Getting Help

YCML documentation is compiled using Appledoc. 

##Example Usage

YCML models and trainers make use of the YCMatrix class to define
input and output datasets. Both for input as well as for output,
each matrix column defines a single training example.

There are plans to implement a proper dataframe class in the future, in
addition to the matrix class, as part of the library.

Basic training and activation, taken from the YCML unit tests:

    #import "YCML/YCML.h"
    #import "YCMatrix/YCMatrix.h"
    #import "YCMatrix/YCMatrix+Manipulate.h"
    #import "YCMatrix/YCMatrix+Advanced.h"

    (...)

    YCMatrix *trainingData   = [self matrixWithCSVName:@"housing" removeFirst:YES];
    YCMatrix *trainingOutput = [trainingData getRow:13];
    YCMatrix *trainingInput  = [trainingData removeRow:13];
    YCELMTrainer *trainer    = [YCELMTrainer trainer];

    YCFFN *model = (YCFFN *)[trainer train:nil inputMatrix:trainingInput outputMatrix:trainingOutput];

    YCMatrix *predictedOutput = [model activateWithMatrix:trainingInput];

A more advanced example, using cross-validation:

    YCMatrix *trainingData   = [self matrixWithCSVName:@"housing" removeFirst:YES];
    [trainingData shuffleColumns];
    YCMatrix *cvData         = [trainingData matrixWithColumnsInRange:NSMakeRange(trainingData.columns - 20, 19)];
    trainingData             = [trainingData matrixWithColumnsInRange:NSMakeRange(0, trainingData.columns - 20)];
    YCMatrix *trainingOutput = [trainingData getRow:13];
    YCMatrix *trainingInput  = [trainingData removeRow:13];
    YCMatrix *cvOutput       = [cvData getRow:13];
    YCMatrix *cvInput        = [cvData removeRow:13];
    YCELMTrainer *trainer    = [YCELMTrainer trainer];
    trainer.settings[@"C"]   = @0.5E-9;

    YCFFN *model = (YCFFN *)[trainer train:nil
    inputMatrix:trainingInput
    outputMatrix:trainingOutput];

    YCMatrix *predictedOutput = [model activateWithMatrix:cvInput];

    [predictedOutput subtract:cvOutput];
    [predictedOutput elementWiseMultiply:predictedOutput];
    double RMSE = sqrt( (1.0/[predictedOutput count]) * [predictedOutput sum] );

YCMatrix *trainingData   = [self matrixWithCSVName:@"housing" removeFirst:YES];
YCMatrix *trainingOutput = [trainingData getRow:13];
YCMatrix *trainingInput  = [trainingData removeRow:13];
YCELMTrainer *trainer    = [YCELMTrainer trainer];

YCFFN *model = (YCFFN *)[trainer train:nil inputMatrix:trainingInput outputMatrix:trainingOutput];

YCMatrix *predictedOutput = [model activateWithMatrix:trainingInput];
    
##File Structure

YCSupervisedModel       Base class for all supervised models
YCSupervisedTrainer     Base class for all supervised model trainers
YCFFN                   General Feed-Forward Network class
YCELMTrainer            Basic Extreme Learning Machines trainer

##References

[1] G.-B. Huang, H. Zhou, X. Ding, and R. Zhang, "Extreme Learning Machine for Regression andMulticlass Classification", IEEE Transactions on Systems, Man, and Cybernetics - Part B:Cybernetics,  vol. 42, no. 2, pp. 513-529, 2012.

##License

__YCML__

 YCML is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 YCML is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with YCML.  If not, see <http://www.gnu.org/licenses/>.