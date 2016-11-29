//
// Matrix+Advanced.h
//
// YCMatrix
//
// Copyright (c) 2013 - 2016 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
// http://yconst.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "Matrix.h"
#import "Matrix+Manipulate.h"
#import "Matrix+Map.h"
#import <Accelerate/Accelerate.h>

/**
 Advanced is a category to the Matrix class, that exposes some
 more complex behavior.
 */
@interface Matrix (Advanced)

/**
 Returns a matrix containing random values uniformly distributed between |lower| and |upper|.
 The parameter matrices should have the same dimensions, and the resulting
 matrix will also be of the same dimensions as the parameters.
 
 @param lower Matrix containing values for the lower bounds.
 @param upper Matrix containing values for the upper bounds.
 
 @return A matrix of random values between lower and upper, and of the same size.
 */
+ (instancetype)uniformRandomLowerBound:(Matrix *)lower upperBound:(Matrix *)upper;

/**
 Returns a matrix of random values uniformly distributed within the specified domain.
 
 @param rows    The number of rows of the matrix.
 @param columns The number of columns of the matrix.
 @param domain  The domain to generate uniform random number within.
 
 @return A matrix of random values.
 */
+ (instancetype)uniformRandomRows:(int)rows columns:(int)columns domain:(YCDomain)domain;

/**
 Returns a matrix containing random values uniformly distributed between |lower| and |upper|.
 The lower and upper matrices should be either row or column matrices. The method will
 generate |count| random row or column matrices, and return them in a single matrix.
 As an example, if the sizes of |lower| and |upper| are mx1 and the value of the count parameter
 is n, the return matrix will be mxn. Conversely, if |lower| and |upper| are 1xm and count is
 n, the return matrix will be nxm.
 
 @param lower The matrix containing the lower bounds for the uniform random numbers.
 @param upper The matrix containing the upper bounds for the uniform random numbers.
 @param count The number of examples to generate.
 
 @return The matrix containing the uniform random numbers.
 
 @warning The lower and upper matrices should be either row or column matrices.
 */
+ (instancetype)uniformRandomLowerBound:(Matrix *)lower
                             upperBound:(Matrix *)upper
                                  count:(int)count;

/**
 Returns a matrix containing random values normally distributed
 with specified mean and variance. The parameter matrices should have 
 the same dimensions, and the resulting matrix will also be of the same 
 dimensions as the parameters.
 
 @param mean Matrix containing values for the means.
 @param variance Matrix containing values for the variances.
 
 @return A matrix of random values between lower and upper, and of the same size.
 */
+ (instancetype)normalRandomMean:(Matrix *)mean variance:(Matrix *)variance;

/**
 Returns a matrix of random values uniformly distributed with specified mean and variance.
 
 @param rows     The number of rows of the matrix.
 @param columns  The number of columns of the matrix.
 @param mean     The mean of the normal distribution.
 @param variance The variance of the normal distribution.

 @return A matrix of random values.
 */
+ (instancetype)normalRandomRows:(int)rows
                         columns:(int)columns
                            mean:(double)mean
                        variance:(double)variance;

/**
 Returns a matrix containing random values normally distributed with specified mean and variance.
 The mean and variance matrices should be either row or column matrices. The method will
 generate |count| random row or column matrices, and return them in a single matrix.
 As an example, if the sizes of |mean| and |variance| are mx1 and the value of the count parameter
 is n, the return matrix will be mxn. Conversely, if |mean| and |variance| are 1xm and count is
 n, the return matrix will be nxm.
 
 @param mean The matrix containing the means of the normally distributed random numbers.
 @param variance The matrix containing the variances of the normally distributed random numbers.
 @param count The number of examples to generate.
 
 @return The matrix containing the normally distributed random numbers.
 
 @warning The mean and variance matrices should be either row or column matrices.
 */
+ (instancetype)normalRandomMean:(Matrix *)mean
                        variance:(Matrix *)variance
                           count:(int)count;

/**
 Returns a matrix of quasi-random values according to the Sobol sequence.
 The parameter matrices should have the same dimensions, and the resulting
 matrix will also be of the same dimensions as the parameters.
 
 @param lower Matrix containing values for the lower bounds.
 @param upper Matrix containing values for the upper bounds.
 @param count The number of points to sample.
 
 @return A matrix of the values corresponding to the Sobol sequence.
 */
+ (instancetype)sobolSequenceLowerBound:(Matrix *)lower
                             upperBound:(Matrix *)upper
                                  count:(int)count;

/**
 Returns a matrix of quasi-random values according to the Halton sequence.
 The parameter matrices should have the same dimensions, and the resulting 
 matrix will also be of the same dimensions as the parameters.
 
 @param lower Matrix containing values for the lower bounds.
 @param upper Matrix containing values for the upper bounds.
 @param count The number of points to sample.
 
 @return A matrix of the values corresponding to the Halton sequence.
 */
+ (instancetype)haltonSequenceWithLowerBound:(Matrix *)lower
                                  upperBound:(Matrix *)upper
                                       count:(int)count;

/**
 Returns the pseudo-inverse of the receiver.
 The calculation is performed using Singular Value Decomposition.
 
 @return The pseudo-inverse of the receiver.
 */
- (Matrix *)pseudoInverse;

/**
 Performs Singular Value Decomposition on the receiver.
 
 @return An NSDictionary containing the "U", "S", "V" components of the SVD of the receiver.
 
 @warning   As a matter of efficiency, and because the corresponding LAPACK function requires
 column-major matrices, the output dictionary will contain the "V" matrix, and not
 it's transpose.
 */
- (NSDictionary *)SVD;

/**
 Returns the X vector that is the solution to the linear system A * X = B, with the receiver being A.
 
 @param B The matrix B.
 
 @return The solution vector X.
 */
- (Matrix *)solve:(Matrix *)B;

/**
 Performs an in-place Cholesky decomposition on the receiver.
 Makes lower triangular R such that R * R' = self. Modifies self.
 */
- (void)cholesky;

/**
 Returns a new matrix by performing Cholesky decomposition on the receiver.
 Makes lower triangular R such that R * R' = self.
 
 @return The matrix resulting from the Cholesky decomposition of the receiver.
 */
- (Matrix *)matrixByCholesky;

/**
 Returns a row matrix containing the real Eigenvalues of the receiver.
 
 @return The resulting row matrix.
 */
- (Matrix *)realEigenvalues;

/**
 Returns an NSDictionary with the results of performing an Eigenvalue decomposition on the receiver.
 
 @return    A dictionary with the following key/value assignments:
 "Real Eigenvalues" : nx1 vector containing the matrix real eigenvalues.
 "Imaginary Eigenvalues" : nx1 vector containing the matrix imaginary eigenvalues.
 "Left Eigenvectors" : nxn matrix containing the matrix left eigenvectors, one per row.
 "Right Eigenvectors" : nxn matrix containing the matrix right eigenvectors, one per row.
 
 @warning The eigenvectors appear per ROW in the result. If you wish to obtain per column
 results, yuo need to transpose the resulting eigenvector matrix.
 */
- (NSDictionary *)eigenvectorsAndEigenvalues;

/**
 Returns the determinant of the receiver.
 
 @return A double value corresponsing to the determinant of the receiver.
 
 @warning This method has not been extensively tested and may contain serious flaws.
 */
- (double)determinant;

/**
 Returns a column matrix containing the sums of the rows of the receiver.
 
 @return The column matrix containing the sums of rows.
 */
- (Matrix *)sumsOfRows;

/**
 Returns a row matrix containing the sums of the columns of the receiver.
 
 @return The row matrix containing the sums of columns.
 */
- (Matrix *)sumsOfColumns;

/**
 Returns a column matrix containing the means of the rows of the receiver.
 
 @return The column matrix containing the means of rows.
 */
- (Matrix *)meansOfRows;

/**
 Returns a row matrix containing the means of the columns of the receiver.
 
 @return The row matrix containing the means of columns.
 */
- (Matrix *)meansOfColumns;

/**
 Returns a column matrix containing the population variances of the rows of the receiver.
 
 @return The column matrix containing the variances of rows.
 
 @warning This calculates the population variance.
 */
- (Matrix *)variancesOfRows;

/**
 Returns a row matrix containing the population variances of the columns of the receiver.
 
 @return The row matrix containing the variances of columns.
 
 @warning This calculates the population variance.
 */
- (Matrix *)variancesOfColumns;

/**
 Returns a column matrix containing the sample variances of the rows of the receiver.
 
 @return The column matrix containing the variances of rows.
 
 @warning This calculates the sample variance.
 */
- (Matrix *)sampleVariancesOfRows;

/**
 Returns a row matrix containing the sample variances of the columns of the receiver.
 
 @return The row matrix containing the variances of columns.
 
 @warning This calculates the sample variance.
 */
- (Matrix *)sampleVariancesOfColumns;

/**
 Returns a column matrix containing the minimum values of each row of the receiver.
 
 @return The column matrix containing the minimum values of each row.
 */
- (Matrix *)minimumsOfRows;

/**
 Returns a column matrix containing the maximum values of each row of the receiver.
 
 @return The column matrix containing the maximum values of each row.
 */
- (Matrix *)maximumsOfRows;

/**
 Returns a row matrix containing the minimum values of each column of the receiver.
 
 @return The row matrix containing the minimum values of each column.
 */
- (Matrix *)minimumsOfColumns;

/**
 Returns a row matrix containing the maximum values of each column of the receiver.
 
 @return The row matrix containing the maximum values of each column.
 */
- (Matrix *)maximumsOfColumns;

/**
 Returns a new matrix with each cell being the result of applying a function to
 the corresponding cell of the receiver.
 
 @param function The function to apply.
 
 @return The matrix of transformed values.
 */
- (Matrix *)matrixByApplyingFunction:(double (^)(double value))function;

/**
 Applies a function to each cell of the receiver.
 
 @param function The function to apply.
 */
- (void)applyFunction:(double (^)(double value))function;

/**
 Returns the multidimensional Euclidean distance of the receiver to another matrix.
 
 @param other The matrix to claculate the distance to.
 
 @return The calculated distance.
 
 @warning This method will accept any kind of matrix as parameter, as long as the
 dimensions are equal.
 
 */
- (double)euclideanDistanceTo:(Matrix *)other;

/**
 Returns the multidimensional Quadrance (square of Euclidean distance of the receiver to another matrix.
 
 @param other The matrix to claculate the quadrance to.
 
 @return The calculated quadrance.
 
 @warning This method will accept any kind of matrix as parameter, as long as the
 dimensions are equal.
 
 */
- (double)quadranceTo:(Matrix *)other;

/**
 Replaces values of the receiver with zeroes or ones, depending on the probability expressed by
 the existing values in the receiver.
 */
- (void)bernoulli;

@end
