
#YCML [![Build Status](https://travis-ci.org/yconst/YCML.svg?branch=master)](https://travis-ci.org/yconst/YCML)

YCML is a Machine Learning and Optimization framework written in Objective-C, and usable in both Objective-C and Swift. YCML runs on OS X and iOS, and mainly focuses on regression problems (although classification problems can be tackled as well), and multi-objective optimization. 

The following algorithms are currently available:

- Gradient Descent Backpropagation [1]
- Resilient Backpropagation (RProp) [2]
- Support Vector Machine Regression using SMO (Currently only linear kernel is available) [3, 4]
- Extreme Learning Machines (ELM) [5]
- Forward Selection using Orthogonal Least Squares (for RBF Net) [6, 7]
- Forward Selection using Orthogonal Least Squares with the PRESS statistic [8]
- Binary Restricted Boltzmann Machines (CD) [9] 

Where applicable, regularized versions of the algrithms have been implemented.

YCML also contains the following optimization algorithms:

- Gradient Descent (Single-Objective, Unconstrained)
- RProp Gradient Descent (Single-Objective, Unconstrained)
- NSGA-II (Multi-Objective, Constrained) [10]
- HypE (Multi-Objective, Constrained, Sampled Hypervolume indicator) [11]

##Features

###Learning

- Embedded model input/output normalization facility.
- Generic Supervised Learning base class that can accommodate a variety of algorithms.
- Modular Backprop class that enables complex graphs, based on Layer objects.
- (new in 0.3.2) Fast Backprop (and RProp) computation using mini-batches to speed up computations through BLAS.
- Powerful Dataframe class, with numerous editing functions, that can be converted to/from Matrix.

###Validation & Testing

- Facilities for k-fold cross validation and Monte Carlo cross-validation.

###Optimization

- Separate optimization routines for single- and multi-objective problems.
- Surrogate class that exposes a predictive model as an objective function, useful for optimization.

###Sampling

- Several different methods for multi-dimensional random number generation, including low-discrepancy sequence generation.
- Several methods for sampling from, splitting and shuffling Dataframes.

###Other

- Based on [YCMatrix](https://github.com/yconst/YCMatrix), a matrix library that makes use of the Accelerate Framework for improved performance.
- Text-based exporting of models.
- NSArray category for basic statistics (mean, median, quartiles, min and max, variance, sd etc.).
- Tools for pseudorandom and quasi-random low discrepancy sequence generation (see note below).

##Getting started

###Setting Up

Import the project in your workspace by dragging the .xcodeproj file. YCML depends on YCMatrix. Since version 0.2.0, YCML includes YCMatrix as a separate target (including copies of YCMatrix files), so you practically don't need to include anything apart from the framework itself.

YCML defines a module. As such, you may import it at the beginning of your files as shown below:

    @import YCML;

In addition, it is possible to import the YCMatrix library, bundled together with YCML, to perform calculations on matrices:

    @import YCMatrix;

###Your first predictive model

Here's a simple training call to an YCML trainer, which returns a trained model, given existing input and output datasets:

    YCFFN *theModel = [[YCRpropTrainer trainer] train:nil input:trainingInput output:trainingOutput];

YCML models and trainers may use YCMatrix instances in place of a dataframe. In such a case, YCML models accept matrices where each matrix column defines a single training example. Here is an example that uses matrices in place of Dataframes:

    YCFFN *theModel = [[YCRpropTrainer trainer] train:nil inputMatrix:trainingInput outputMatrix:trainingOutput];

The resulting model may subsequently be used to make predictions, given a dataset or matrix:

    YCDataframe *prediction = [theModel predict:testInput];

###Working with YCML Dataframes

Using the YCDataframe class, it is easy to prepare your data. To add examples to an instance of YCDataframe, call the -addSampleWithData: method, passing a NSDictionary with the data to be added. If the attributes indicated in the supplied dictionary are not in the dataframe yet, they are created automatically (including data). The example below shows how to create a new dataframe, and add a couple of records:

    YCDataframe *frame = [YCDataframe dataframe];
    [frame addSampleWithData:@{@"X1" : @1.0, @"X2" : @2.0, @"X3" : @-5.0}];
    [frame addSampleWithData:@{@"X1" : @5.5, @"X2" : @-3.0, @"X3" : @-1.5}];

With two dataframes, one for input (independent variables) and one for output (dependent variables), you may easily train a predictive model, as described previously.

###Further Help

For the complete reference, you may compile YCML documentation using Appledoc. 

##Examples

###Training and activation (Objective-C, using Matrices):

    YCMatrix *trainingData   = [self matrixWithCSVName:@"housing" removeFirst:YES];
    YCMatrix *trainingOutput = [trainingData getRow:13]; // Output row == 13
    YCMatrix *trainingInput  = [trainingData removeRow:13];
    YCELMTrainer *trainer    = [YCELMTrainer trainer];

    YCFFN *model = (YCFFN *)[trainer train:nil inputMatrix:trainingInput outputMatrix:trainingOutput];

    YCMatrix *predictedOutput = [model activateWithMatrix:trainingInput];

Cross-validation example, from data input to presentation of results:
    
    // Change "filePath" with your file path
    NSURL *url = [[NSURL alloc] initFileURLWithPath:filePath]; 
    NSMutableArray *dataarray = [[NSArray arrayWithContentsOfCSVURL: url] mutableCopy];
    
    // First row is taken as header
    NSArray *header = [dataarray firstObject];
    [dataarray removeObjectAtIndex:0];

    YCDataframe *input = [YCDataframe dataframe];
    for (NSArray *record in dataarray)
    {
        NSDictionary *recordDictionary = [NSDictionary dictionaryWithObjects:record forKeys:header];
        [input addSampleWithData:recordDictionary];
    }

    YCDataframe *output = [YCDataframe dataframe];

    // Change outputAttribute with your target (dependent) variable
    NSArray *outputData = [input allValuesForAttribute:outputAttribute];
    [input removeAttributeWithIdentifier:eAttribute];
    [output addAttributeWithIdentifier:eAttribute data:outputData];

    YCkFoldValidation *cv = [[YCkFoldValidation alloc] initWithSettings:@{@"Folds" : @10}];
    
    // Choose the trainer/model that you wish to test
    YCBackPropTrainer *trainer = [YCRpropTrainer trainer];

    NSLog(@"Results:\n %@", [cv test:trainer input:input output:output]);

###Training and activation (Swift, using Matrices):

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

### A note on Pseudorandom and Quasi-random Number Generation



##Framework Architecture

The basic predictive model building block is the `YCGenericModel` class. It's training algorithm counterpart inherits from the `YCGenericTrainer` class. Most of the models included in the library are supervised learning models, and they inherit from a subclass of `YCGenericModel`, `YCSupervisedModel`. Their corresponding training algorithms inherit from the `YCSupervisedTrainer` class. These classes offer basic infrastructure to support training and activation, such as optional scaling and normalization of inputs, conversion between datasets and matrices etc. As such, the models and trainers themselves only contain algorithm implementations (for the most part).

A significant supervised learning model is the Feed Forward Network, which is implemented in the `YCFFN` class. `YCFFN` is a flexible class that can be used to represent a wide array of feed-forward models, including one with large number of layers, such as Deep Neural Nets. `YCFFN` is a model that consists of several layer modules, each corresponding to a layer of activation in a hypothetical Neural Net. The layers are subclasses of the `YCModelLayer` class. In particular, for classic neural nets, layers are subclasses of `YCFullyConnectedLayer`, itself a subclass of `YCModelLayer`. 

In forward propagation, the input signal is being propagated through each single layer, and appears as the output. Propagation in a densely connected layer involves application of weights and biases to the input, and transformation by the activation function. The scaling/normalization of the model input and output happen separately from the layers.

Currently implemented FFN layers differ in their activation function. Linear, Sigmoid, ReLU and Tanh -based layers have been implemented.

##References

[1] D. Rumelhart, G. Hinton and R. Williams. Learning Internal Representations by Error Propagation, Parallel Distrib. Process. Explor. Microstruct. Cogn. Vol. 1, Cambridge, MA, USA: MIT Press; pp. 318–362, 1985.

[2] M. Riedmiller, H. Braun. A direct adaptive method for faster backpropagation learning: the RPROP algorithm. IEEE Int. Conf. Neural Networks; pp. 586-591, 1993.

[3] JC. Platt. Fast Training of Support Vector Machines Using Sequential Minimal Optimization. Adv Kernel Methods pp. 185-208, 1998

[4] GW. Flake, S. Lawrence. Efficient SVM regression training with SMO. Mach Learn 46; pp.271–90, 2002.

[5] G.-B. Huang, H. Zhou, X. Ding, and R. Zhang. Extreme Learning Machine for Regression and Multiclass Classification, IEEE Transactions on Systems, Man, and Cybernetics - Part B:Cybernetics, vol. 42, no. 2, pp. 513-529, 2012.

[6] S. Chen, CN Cowan, PM Grant. Orthogonal least squares learning algorithm for radial basis function networks. IEEE Trans Neural Netw, vol. 2, no. 2, pp. 302–9, 1991.

[7] S. Chen, E. Chng, K. Alkadhimi. Regularized orthogonal least squares algorithm for constructing radial basis function networks. Int J Control 1996.

[8] X. Hong, P. Sharkey, K. Warwick. Automatic nonlinear predictive model-construction algorithm using forward regression and the PRESS statistic. IEEE Proc - Control Theory Appl. vol. 150, no. 3, pp. 245–54, 2003

[9] G. Hinton. Training Products of Experts by Minimizing Contrastive Divergence. Neural Comput. vol. 14, no. 8, pp.1771–800, 2002.

[10] K. Deb, A. Pratap, S. Agarwal, T. Meyarivan. A fast and elitist multiobjective genetic algorithm: NSGA-II. IEEE Trans Evol Comput. vol. 6, pp. 182–97, 2002.

[11] J. Bader, E. Zitzler. HypE: An algorithm for fast hypervolume-based many-objective optimization. Evol Comput 19, pp. 45–76, 2011.

##License 

Copyright (c) 2015-2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.

YCML is licensed under the GPLv3. For other licensing options, please contact the author.

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