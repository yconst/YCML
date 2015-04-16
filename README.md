
#YCML

YCML is a Machine Learning framework in Objective-C and Swift.  
The following algorithms are avilable:

- Extreme Learning Machines (ELM) [1]
- Gradient Descent Backpropagation [2]
- Resilient Backpropagation (RProp) [3]

More algorithms soon to follow. 

##Features

- Embedded model input/output normalization facility.
- Generic Supervised Learning base class that can accommodate a variety of algorithms.
- Ppowerful Dataframe class, with numerous editing functions, that can be converted to/from Matrix.
- Based on [YCMatrix](https://github.com/yconst/YCMatrix), a matrix library that makes use of the Accelerate Framework for improved performance.

##Getting started

Import the project in your workspace by dragging the .xcodeproj file. YCML depends on YCMatrix, which has been included as a Git submodule.

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

[1] G.-B. Huang, H. Zhou, X. Ding, and R. Zhang. Extreme Learning Machine for Regression and Multiclass Classification, IEEE Transactions on Systems, Man, and Cybernetics - Part B:Cybernetics, vol. 42, no. 2, pp. 513-529, 2012.

[2] D. Rumelhart, G. Hinton and R. Williams. Learning Internal Representations by Error Propagation, Parallel Distrib. Process. Explor. Microstruct. Cogn. Vol. 1, Cambridge, MA, USA: MIT Press; pp. 318–362, 1985.

[3] M. Riedmiller, H. Braun. A direct adaptive method for faster backpropagation learning: the RPROP algorithm. IEEE Int. Conf. Neural Networks; pp. 586-591, 1993.

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