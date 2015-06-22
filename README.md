
#YCML

YCML is a Machine Learning framework written in Objective-C, and also available for use in Swift.  
The following algorithms are currently available:

- Gradient Descent Backpropagation [1]
- Resilient Backpropagation (RProp) [2]
- Extreme Learning Machines (ELM) [3]
- Forward Selection using Orthogonal Least Squares (for RBF Net) [4, 5]

Where applicable, regularized versions of the algrithms have been implemented.

More algorithms soon to follow. 

##Features

- Embedded model input/output normalization facility.
- Generic Supervised Learning base class that can accommodate a variety of algorithms.
- Powerful Dataframe class, with numerous editing functions, that can be converted to/from Matrix.
- Based on [YCMatrix](https://github.com/yconst/YCMatrix), a matrix library that makes use of the Accelerate Framework for improved performance.

##Getting started

Import the project in your workspace by dragging the .xcodeproj file. YCML depends on YCMatrix. Since version 0.2.0, YCML includes YCMatrix as a separate target (including copies of YCMatrix files), and as such does away with Git submodules.

Cocoapods support might come at a later time.

##Getting Help

YCML documentation is compiled using Appledoc. 

##Example Usage

Here's the simplest training call to an YCML trainer, which returns a trained model:

    YCFFN *theModel = [[YCRpropTrainer trainer] train:nil input:trainingInput output:trainingOutput];

YCML models and trainers may use YCMatrix instances in place of a dataframe. In such a case, YCML models accept matrices where each matrix column defines a single training example. Here is an example that uses matrices in place of Dataframes:

    YCFFN *theModel = [[YCRpropTrainer trainer] train:nil inputMatrix:trainingInput outputMatrix:trainingOutput];



Basic training and activation (Objective-C, using Matrices):

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

A more advanced example, using cross-validation (Objective-C, using Matrices):

    YCMatrix *trainingData   = [self matrixWithCSVName:@"housing" removeFirst:YES];
    [trainingData shuffleColumns];
    YCMatrix *cvData         = [trainingData matrixWithColumnsInRange:NSMakeRange(trainingData.columns - 20, 19)];
    trainingData             = [trainingData matrixWithColumnsInRange:NSMakeRange(0, trainingData.columns - 20)];
    YCMatrix *trainingOutput = [trainingData getRow:13];
    YCMatrix *trainingInput  = [trainingData removeRow:13];
    YCMatrix *cvOutput       = [cvData getRow:13];
    YCMatrix *cvInput        = [cvData removeRow:13];
    YCELMTrainer *trainer    = [YCELMTrainer trainer];
    trainer.settings[@"C"]   = @8;
    trainer.settings[@"Hidden Layer Size"] = @1000

    YCFFN *model = (YCFFN *)[trainer train:nil inputMatrix:trainingInput outputMatrix:trainingOutput];

    YCMatrix *predictedOutput = [model activateWithMatrix:cvInput];

    [predictedOutput subtract:cvOutput];
    [predictedOutput elementWiseMultiply:predictedOutput];
    double RMSE = sqrt( (1.0/[predictedOutput count]) * [predictedOutput sum] );

The last example written in Swift:

    var trainingData = self.matrixWithCSVName("housing", removeFirst: true)
    trainingData.shuffleColumns()
    var cvData = trainingData.matrixWithColumnsInRange(NSMakeRange(trainingData.columns-20, 19))
    trainingData = trainingData.matrixWithColumnsInRange(NSMakeRange(0, trainingData.columns-20))
    var trainingOutput = trainingData.getRow(13)
    var trainingInput = trainingData.removeRow(13)
    var cvOutput = cvData.getRow(13)
    var cvInput = cvData.removeRow(13)
    var trainer = YCELMTrainer()
    trainer.settings["C"] = 8
    trainer.settings["Hidden Layer Size"] = 1000

    var model = trainer.train(nil, inputMatrix: trainingInput, outputMatrix: trainingOutput)

    var predictedOutput = model.activateWithMatrix(cvInput)

    predictedOutput.subtract(cvOutput)
    predictedOutput.elementWiseMultiply(predictedOutput)
    var RMSE = sqrt(1.0 / Double(predictedOutput.columns) * predictedOutput.sum)
    NSLog("%@", RMSE)
    XCTAssertLessThan(RMSE, 9.0, "RMSE above threshold")

##References


[1] D. Rumelhart, G. Hinton and R. Williams. Learning Internal Representations by Error Propagation, Parallel Distrib. Process. Explor. Microstruct. Cogn. Vol. 1, Cambridge, MA, USA: MIT Press; pp. 318–362, 1985.

[2] M. Riedmiller, H. Braun. A direct adaptive method for faster backpropagation learning: the RPROP algorithm. IEEE Int. Conf. Neural Networks; pp. 586-591, 1993.

[3] G.-B. Huang, H. Zhou, X. Ding, and R. Zhang. Extreme Learning Machine for Regression and Multiclass Classification, IEEE Transactions on Systems, Man, and Cybernetics - Part B:Cybernetics, vol. 42, no. 2, pp. 513-529, 2012.

[4] S. Chen, CN Cowan, PM Grant. Orthogonal least squares learning algorithm for radial basis function networks. IEEE Trans Neural Netw, vol. 2, no. 2, pp. 302–9, 1991.

[5] S. Chen, E. Chng, K. Alkadhimi. Regularized orthogonal least squares algorithm for constructing radial basis function networks. Int J Control 1996.

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