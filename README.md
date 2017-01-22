
<p align="center">
<img src="https://raw.githubusercontent.com/yconst/YCML/master/Logo.png"
width=600 height=167>
</p>

<p align="center">
<a href="https://travis-ci.org/yconst/YCML">
<img src="https://travis-ci.org/yconst/YCML.svg?branch=master"
alt="Build Status">
</a>
<a href="https://zenodo.org/badge/latestdoi/20003/yconst/YCML">
<img src="https://zenodo.org/badge/20003/yconst/YCML.svg"
alt="DOI">
</a>
<a href="https://raw.githubusercontent.com/yconst/YCML/master/COPYING">
<img src="https://img.shields.io/badge/license-GPL-blue.svg"
alt="GPL v3 License">
</a>
</p>

YCML is an Artificial Intelligence, Machine Learning and Optimization framework written in Objective-C. YCML can be used both in Objective-C as well as in Swift. YCML has been verified to run on MacOS and iOS. 

Above all, YCML attempts to bring high-quality published algorithms to Swift/Objective-C, using optimized implementations. Referenced papers for the implementation of each algorithm are available at the end of this document.

YCML contains currently more than 30 high-level unit tests, that cover every one of the implemented algorithms, not only in terms of functioning but also in terms of *performance*, i.e. each algorithm is tested to meet certain performance standards.

Finally, YCML tries to maintain a scientific attitude throughout, and keep the AI "prose" to the minimum.

### At a glance

- Nine Machine Learning Algorithm Implementations for Supervised Learning
- Two Multi-Objective Genetic Algorithm Variants
- One Ranking Algorithm (Rank Centrality)
- Helper classes & tools for validation and testing

### Introduction

YCML can be used to tackle problems in the field of Machine Learning, the field of Computational Optimization, as well as the intersection of the two fields.

#### Machine Learning

The scientific field of Machine Learning is studying ways in which we may enable computers to, broadly speaking, learn by experience, instead of the more conventional explicit programming approach. Machine Learning algorithms enable machines to learn a task by being exposed to examples, and subsequently generalize the behavior suggested by the seen examples to unseen ones.

YCML mainly focuses on regression problems, which is a class of problems where the goal is to come up with a model that can accurately predict a real number (also called the dependent or target variable), based on information present in one or more input variables. This is a commonly occusing problem in many fields among which:

- Stock market forecasting
- Property price prediction
- Robotics and control
- Mechanical and material property prediction
- Approximating results of lengthy and complicated experiments, as well as simulations (surrogate modeling / meta-modeling)
- Online advertising prediction
- Medical diagnosis automation

Despite the focus on regression, however, classification problems can be tackled equally well using YCML, by making a few changes to the input and output data.

#### Computational (Multi-Objective) Optimization

YCML offers a few algorithms that allow tackling Optimization problems. Specifically, it focuses on Multi-Objective Real Parameter Optimization problems. 

Multi-Objective problems are a class of problems where more than one goals exist, and which are conflicting to each other. That means that by improving design performance of one goal, performance on at least one other goal is sacrificed. This characteristic of Multi-Objective problems gives birth to the fact that there are no all-round optimzal solutions to be found in this type of problems. Rather, what we are usually looking for are best-tradeoffs. A best-tradeoff design is one for which there does not exist any other that performs better in all aspects. In the context of Multi-Objective optimization, these are also called Non-Dominated design solutions.

YCML implements a couple Multi-Objective Evolutionary Algorithms (MOEAs). MOEAs are a class of stochastic optimization algorithms that work using a population of solutions, which they gradually evolve towards optimality. They are using a carefully calculated combination of randomization on the one hand, and "distilling" of the best design features on the other hand. Through such strategies, they are able to efficiently search the space of possible design solutions for "optimal" ones.

## Features

### Learning

The following algorithms are currently available:

#### Supervised 

- Linear Regression
- Gradient Descent Backpropagation [1]
- Resilient Backpropagation (RProp) [2]
- Support Vector Machine Regression (SVR) using SMO (Linear & RBF kernels) [3, 4]
- Extreme Learning Machines (ELM) [5]
- Forward Selection using Orthogonal Least Squares (for RBF Net) [6, 7]
- Forward Selection using Orthogonal Least Squares with the PRESS statistic [8]
- Kernel Process Regression

#### Unsupervised

- Binary Restricted Boltzmann Machines (CD) [9] 

#### Learning features:

- Embedded model input/output normalization facility.
- Generic Supervised Learning base class that can accommodate a variety of algorithms.
- Modular Backprop class that enables complex graphs, based on Layer objects.
- (new in 0.3.2) Fast Backprop (and RProp) computation using mini-batches to speed up computations through BLAS.
- Powerful Dataframe class, with numerous editing functions, that can be converted to/from Matrix.
- Where applicable, regularized versions of the algrithms have been implemented.

### Optimization

The following MO optimization algorithms are implemented:

- NSGA-II (Multi-Objective, Constrained) [10]
- HypE (Multi-Objective, Constrained, Sampled Hypervolume indicator) [11]

In addition, a couple of basic optimization algorithms are impemented:

- Gradient Descent (Single-Objective, Unconstrained)
- RProp Gradient Descent (Single-Objective, Unconstrained)

#### Optimization features:

- Separate optimization routines for single- and multi-objective problems.
- Surrogate class that exposes a predictive model as an objective function, useful for optimization.

### Ranking

- Rank Centrality [12]

### Sampling

- Several different methods for multi-dimensional random number generation, including low-discrepancy sequence generation.
- Several methods for sampling from, splitting and shuffling Dataframes.

### Validation & Testing

- Facilities for k-fold cross validation and Monte Carlo cross-validation.

### Other

- Exporting of generated models as [PMML](https://en.wikipedia.org/wiki/Predictive_Model_Markup_Language) (MacOS only) and Text Report (JSON to follow soon).
- Based on [YCMatrix](https://github.com/yconst/YCMatrix), a matrix library that makes use of the Accelerate Framework for improved performance.
- NSMutableArray Subclass offering fast (cached) statistics (mean, median, quartiles, min and max, variance, sd etc.).
- Tools for pseudorandom and quasi-random low discrepancy sequence generation.

## Getting started

### Setting Up

Import the project in your workspace by dragging the .xcodeproj file. YCML depends on YCMatrix. Since version 0.2.0, YCML includes YCMatrix as a separate target (including copies of YCMatrix files), so you practically don't need to include anything apart from the framework itself.

YCML defines a module. As such, you may import it at the beginning of your files as shown below:

    @import YCML;

In addition, it is possible to import the YCMatrix library, bundled together with YCML, to perform calculations on matrices:

    @import YCMatrix;

## Learning YCML

Take a look at the [YCML Wiki](https://github.com/yconst/YCML/wiki) for tutorials and examples.

For the complete reference, you may compile YCML documentation using Appledoc. 

## Framework Architecture

The basic predictive model building block is the `YCGenericModel` class. It's training algorithm counterpart inherits from the `YCGenericTrainer` class. Most of the models included in the library are supervised learning models, and they inherit from a subclass of `YCGenericModel`, `YCSupervisedModel`. Their corresponding training algorithms inherit from the `YCSupervisedTrainer` class. These classes offer basic infrastructure to support training and activation, such as optional scaling and normalization of inputs, conversion between datasets and matrices etc. As such, the models and trainers themselves only contain algorithm implementations (for the most part).

A significant supervised learning model is the Feed Forward Network, which is implemented in the `YCFFN` class. `YCFFN` is a flexible class that can be used to represent a wide array of feed-forward models, including one with large number of layers, such as Deep Neural Nets. `YCFFN` is a model that consists of several layer modules, each corresponding to a layer of activation in a hypothetical Neural Net. The layers are subclasses of the `YCModelLayer` class. In particular, for classic neural nets, layers are subclasses of `YCFullyConnectedLayer`, itself a subclass of `YCModelLayer`. 

In forward propagation, the input signal is being propagated through each single layer, and appears as the output. Propagation in a densely connected layer involves application of weights and biases to the input, and transformation by the activation function. The scaling/normalization of the model input and output happen separately from the layers.

Currently implemented FFN layers differ in their activation function. Linear, Sigmoid, ReLU and Tanh -based layers have been implemented.

### Input and Output 

YCML models can be exported in various formats. Currently supported are PMML and Text formats (report). Unfortunately, due to lack of support for NSXML in iOS, PMML export is setup to compile only under MacOS, and as such is only available under that platform. Plans for a JSON format are underway. The IO subsystem has been designed as a series of Objective-C Categories that follow the class hierarchy of the models in YCML. Categories of parent classes are responsible for the serialization of base properties, while subclasses add more specfic information. Implementation in Categories means that the whole subsystem can be implemented in separate source files, leaving the main model files containing only the actual model logic. Clean and efficient.

This strategy has been currently implemented for most predictive models (subclasses of YCSupervisedModel). Plans are underway for the implementation throughout the framework. Implementation of the PMML format are based on the definition and [this set of examples](http://dmg.org/pmml/pmml_examples/index.html). In case you find out any inconsistencies, please chime in!

## References

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

[12] S. Negahban, S. Oh, and D. Shah, “Iterative Ranking from Pair-wise Comparisons,” Adv. Neural Inf. Process. Syst. 25, pp. 2474–2482, 2012.

## License 

Copyright (c) 2015-2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.

YCML is licensed under the GPLv3. For other licensing options, please contact the author at the following address:
contact (at) yconst [dot] com

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
