//
// Matrix+Advanced.m
//
// YCMatrix
//
// Copyright (c) 2013 - 2015 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
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

// References for this document:
// http://jira.madlib.net/secure/attachment/10019/matrixpinv.cpp
// http://vismod.media.mit.edu/pub/tpminka/MRSAR/lapack.c
//

#import "Matrix+Advanced.h"
#import "Constants.h"

static void SVDColumnMajor(double *A, __CLPK_integer rows, __CLPK_integer columns,
                           double **s, double **u, double **vt);
static void pInv(double *A, int rows, int columns, double *Aplus);
static void MEVV(double *A, int m, int n, double *vr, double *vi, double *vecL, double *vecR);

@implementation Matrix (Advanced)

+ (instancetype)randomValuesMatrixWithLowerBound:(Matrix *)lower upperBound:(Matrix *)upper
{
    if (lower.rows != upper.rows || lower.columns != upper.columns)
    {
        @throw [NSException exceptionWithName:@"YCMatrixException"
                                       reason:@"Lower and upper bounds are not of the same size."
                                     userInfo:nil];
    }
    Matrix *result = [lower copy];
    Matrix *range = [upper matrixBySubtracting:lower];
    
    for (int i=0, j=(int)[result count]; i<j; i++)
    {
        result->matrix[i] += ((double)arc4random() / ARC4RANDOM_MAX) * range->matrix[i];
    }
    return result;
}

+ (instancetype)randomValuesMatrixOfRows:(int)rows columns:(int)columns domain:(YCDomain)domain
{
    Matrix *result = [Matrix matrixOfRows:rows Columns:columns];
    for (int i=0, j=(int)[result count]; i<j; i++)
    {
        result->matrix[i] = ((double)arc4random() / ARC4RANDOM_MAX) * domain.length + domain.location;
    }
    return result;
}

- (Matrix *)pseudoInverse
{
    Matrix *ret = [Matrix matrixOfRows:self->columns Columns:self->rows];
    
    pInv(self->matrix, self->rows, self->columns, ret->matrix);
    return ret;
}

- (NSDictionary *)SVD
{
    double *ua = NULL;
    double *sa = NULL;
    double *va = NULL;
    
    SVDColumnMajor([self matrixByTransposing]->matrix, (__CLPK_integer)rows, (__CLPK_integer)columns, &sa, &ua, &va);
    
    Matrix *U = [[Matrix matrixFromArray:ua Rows:self->columns Columns:self->rows Mode:YCMWeak] matrixByTransposing]; // mxm
    Matrix *S = [Matrix matrixOfRows:self->columns Columns:self->columns ValuesInDiagonal:sa Value:0]; // mxn
    Matrix *V = [Matrix matrixFromArray:va Rows:self->columns Columns:self->columns Mode:YCMWeak]; // nxn

    return @{@"U" : U, @"S" : S, @"V" : V};
}

- (Matrix *)solve:(Matrix *)B
{
    [self checkSquare];
    Matrix *bTranspose = B;
    if (B->columns > 1)
    {
        bTranspose = [B matrixByTransposing];
    }
    Matrix *aTranspose = [self matrixByTransposing];
    
    __CLPK_integer n = self->rows;
    __CLPK_integer nrhs = B->columns;
    __CLPK_integer lda = self->rows;
    __CLPK_integer ldb = self->rows;
    
    __CLPK_integer ipiv[n];
    
    __CLPK_integer info = 0;
    
    dgesv_(&n, &nrhs, aTranspose->matrix, &lda, ipiv, bTranspose->matrix, &ldb, &info);
    
    if(info < 0)
    {
        @throw [NSException exceptionWithName:@"YCMatrixException"
                                       reason:@"Error while solving linear system A*X=B."
                                     userInfo:nil];
    }
    if(info > 0)
    {
        @throw [NSException exceptionWithName:@"YCMatrixException"
                                       reason:@"Matrix U is singular."
                                     userInfo:nil];
    }
    
    if (B->columns > 1)
    {
        return [bTranspose matrixByTransposing];
    }
    return bTranspose;
}

- (void)cholesky
{
    char uplo = 'U';
    __CLPK_integer rank = self->rows;
    __CLPK_integer info;
    __CLPK_integer i,j;

    dpotrf_(&uplo, &rank, self->matrix, (__CLPK_integer *)&self->rows, &info);
    
    if(info > 0)
    {
        @throw [NSException exceptionWithName:@"YCMatrixException"
                                       reason:@"Matrix is not positive definite."
                                     userInfo:nil];
    }
    
    /* clear out the upper triangular */
    for(i=0; i<self->rows; i++)
    {
        for(j=i+1; j<self->columns; j++)
        {
            self->matrix[i*self->columns + j] = 0.0;
        }
    }
}

- (Matrix *)matrixByCholesky
{
    Matrix *newMatrix = [self copy];
    [newMatrix cholesky];
    return newMatrix;
}

- (Matrix *)eigenvalues
{
    [self checkSquare];
    double *evArray = malloc(self->rows * sizeof(double));
    
    MEVV(self->matrix, self->rows, self->columns, evArray, nil, nil, nil);
    
    return [Matrix matrixFromArray:evArray Rows:1 Columns:self->columns];
}

- (NSDictionary *)eigenvaluesAndEigenvectors
{
    [self checkSquare];
    int m = self->rows;
    int n = self->columns;
    double *evArray = malloc(m * sizeof(double));
    double *leVecArray = malloc(m * n * sizeof(double));
    double *reVecArray = malloc(m * n * sizeof(double));
    
    MEVV(self->matrix, m, n, evArray, nil, leVecArray, reVecArray);
    
    Matrix *evMatrix = [Matrix matrixFromArray:evArray Rows:1 Columns:n];
    Matrix *leVecMatrix = [Matrix matrixFromArray:leVecArray Rows:m Columns:n];
    Matrix *reVecMatrix = [Matrix matrixFromArray:reVecArray Rows:m Columns:n];
    return @{@"Eigenvalues":evMatrix,
             @"Left Eigenvectors":leVecMatrix,
             @"Right Eigenvectors":reVecMatrix};
}

- (double)determinant
{
    __CLPK_integer info;
    double det = 1.0;
    __CLPK_integer neg = 0;
    
    [self checkSquare];
    
    __CLPK_integer m = self->rows;
    __CLPK_integer length = m*m;
    
    double *A = malloc(length * sizeof(double));
    memcpy(A, self->matrix, length * sizeof(double));
    
    __CLPK_integer *ipvt = malloc(m * sizeof(int));
    
    dgetrf_(&m, &m, A, &m, ipvt, &info);
    
    if(info > 0) {
        /* singular matrix */
        free(ipvt);
        free(A);
        return 0.0;
    }
    
    /* Take the product of the diagonal elements */
    for (int c1 = 0; c1 < m; c1++) {
        double c = A[c1 + m*c1];
        det *= c;
        if (ipvt[c1] != (c1+1)) neg = !neg;
    }
    
    free(ipvt);
    free(A);
    
    /* Since tmp is an LU decomposition of a rowwise permutation of A,
     multiply by appropriate sign */
    return neg?-det:det;
}

- (Matrix *)sumsOfRows
{
    Matrix *result = [Matrix matrixOfRows:self->rows Columns:1];
    for (int i=0; i<self->rows; i++)
    {
        double sum = 0;
        for (int j=0; j<self->columns; j++)
        {
            sum += self->matrix[i*self->columns + j];
        }
        result->matrix[i] = sum;
    }
    return result;
}

- (Matrix *)sumsOfColumns
{
    Matrix *result = [Matrix matrixOfRows:1 Columns:self->columns];
    for (int i=0; i<self->columns; i++)
    {
        double sum = 0;
        for (int j=0; j<self->rows; j++)
        {
            sum += self->matrix[j*self->columns + i];
        }
        result->matrix[i] = sum;
    }
    return result;
}

- (Matrix *)meansOfRows
{
    Matrix *means = [Matrix matrixOfRows:self->rows Columns:1];
    for (int i=0; i<rows; i++)
    {
        double rowMean = 0;
        for (int j=0; j<columns; j++)
        {
            rowMean += matrix[i*self->columns + j];
        }
        rowMean /= columns;
        means->matrix[i] = rowMean;
    }
    return means;
}

- (Matrix *)meansOfColumns
{
    Matrix *means = [Matrix matrixOfRows:1 Columns:self->columns];
    for (int i=0; i<columns; i++)
    {
        double columnMean = 0;
        for (int j=0; j<rows; j++)
        {
            columnMean += matrix[j*self->columns + i];
        }
        columnMean /= rows;
        means->matrix[i] = columnMean;
    }
    return means;
}

- (Matrix *)variancesOfRows
{
    Matrix *means = [self meansOfRows];
    Matrix *d2 = [self matrixBySubtractingColumn:means];
    [d2 elementWiseMultiply:d2];
    Matrix *sums = [d2 sumsOfRows];
    [sums multiplyWithScalar:1.0/self.columns];
    return sums;
}

- (Matrix *)variancesOfColumns
{
    Matrix *means = [self meansOfColumns];
    Matrix *d2 = [self matrixBySubtractingRow:means];
    [d2 elementWiseMultiply:d2];
    Matrix *sums = [d2 sumsOfColumns];
    [sums multiplyWithScalar:1.0/self.rows];
    return sums;
}

- (Matrix *)sampleVariancesOfRows
{
    Matrix *means = [self meansOfRows];
    Matrix *d2 = [self matrixBySubtractingColumn:means];
    [d2 elementWiseMultiply:d2];
    Matrix *sums = [d2 sumsOfRows];
    [sums multiplyWithScalar:1.0/(self.columns - 1)];
    return sums;
}

- (Matrix *)sampleVariancesOfColumns
{
    Matrix *means = [self meansOfColumns];
    Matrix *d2 = [self matrixBySubtractingRow:means];
    [d2 elementWiseMultiply:d2];
    Matrix *sums = [d2 sumsOfColumns];
    [sums multiplyWithScalar:1.0/(self.rows - 1)];
    return sums;
}

- (Matrix *)matrixByApplyingFunction:(double (^)(double value))function
{
    Matrix *newMatrix = [self copy];
    [newMatrix applyFunction:function];
    return newMatrix;
}

- (void)applyFunction:(double (^)(double value))function
{
    NSUInteger count = [self count];
    for (int i=0; i<count; i++)
    {
        self->matrix[i] = function(self->matrix[i]);
    }
}

- (double)euclideanDistanceTo:(Matrix *)other
{
    return sqrt([self quadranceTo:other]);
}

- (double)quadranceTo:(Matrix *)other
{
    Matrix *result = [self matrixBySubtracting:other];
    [result elementWiseMultiply:result];
    return [result sum];
}

@end

static void MEVV(double *A, int m, int n, double *vr, double *vi, double *vecL, double *vecR)
/*
 
 Fills vr and vi with the real and imaginary parts of the eigenvalues of A.
 If vr or vi is NULL, that part of the result will not be returned.
 Returns 0 if an error occurred.
 
 */
{
    char jobvl = vecL?'V':'N', jobvr = vecR?'V':'N';
    __CLPK_integer vecLSize = vecL?n:1, vecRSize = vecR?n:1;
    __CLPK_integer rank = m;
    double *dup;
    __CLPK_integer lwork;
    double *work;
    __CLPK_integer info;
    
    double *wr = vr ? vr : malloc(rank * sizeof(double));
    double *wi = vi ? vi : malloc(rank * sizeof(double));
    
    /* make a copy since dgeev clobbers A */
    dup = malloc(m * n * sizeof(double));
    memcpy(dup, A, m * n * sizeof(double));
    
    lwork = 3 * rank;
    work = malloc(lwork *sizeof(double));
    
    dgeev_(&jobvl, &jobvr, &rank, dup, &rank,
           wr, wi, vecL, &vecLSize, vecR, &vecRSize, work, &lwork, &info);
    free(dup);
    free(work);
    if(vr == NULL) free(wr);
    if(vi == NULL) free(wi);
    if(info > 0)
    {
        @throw [NSException exceptionWithName:@"YCMatrixException"
                                       reason:@"Error while calculating Eigenvalues."
                                     userInfo:nil];
    }
}

static void SVDColumnMajor(double *A, __CLPK_integer rows, __CLPK_integer columns,
                           double **s, double **u, double **vt)
/*
 
 Compute the Singular Value Decomposition of *column-major* matrix A
 
 Author:  Luke Lonergan
 Date:    5/31/08
 License: Use pfreely
 
 */
{
    __CLPK_integer    i;
    __CLPK_integer    lwork, *iwork;
    double     *work;
    double     *S, *U, *Vt;
    char        achar='A';   /* ? */
    
    /*
     * The factors of A: S, U and Vt
     * U, Sdiag and Vt are the factors of the pseudo inverse of A, the
     * components of the singular value decomposition of A
     */
    S = (double *) malloc(sizeof(double)*MIN(rows,columns));
    U = (double *) malloc(sizeof(double)*rows*rows);
    Vt = (double *) malloc(sizeof(double)*columns*columns);
    
    /*
     * First call of dgesdd is with lwork=-1 to calculate an optimal value of
     * lwork
     */
    iwork = (__CLPK_integer *)malloc(sizeof(__CLPK_integer)*8*MIN(rows,columns));
    lwork=-1;
    
    /* Need a single location in work to store the recommended value of lwork */
    work = (double *) malloc(sizeof(double)*1);
    
    __CLPK_integer lda = rows;
    __CLPK_integer ldu = rows;
    __CLPK_integer ldvt = columns;
    
    dgesdd_( &achar, &rows, &columns, A, &lda, S, U, &ldu, Vt, &ldvt, work, &lwork, iwork, &i );
    
    if (i != 0) {
        free(S);
        free(U);
        free(Vt);
        free(iwork);
        free(work);
        @throw [NSException exceptionWithName:@"YCMatrixException"
                                       reason:@"Error while performing SVD."
                                     userInfo:nil];
    } else {
        lwork = (int) work[0];
        free(work);
    }
    
    /*
     * Allocate the space needed for the work array using the value of lwork
     * obtained in the first call of dgesdd_
     */
    work = (double *) malloc(sizeof(double)*lwork);
    dgesdd_( &achar, &rows, &columns, A, &lda, S, U, &ldu, Vt, &ldvt, work, &lwork, iwork, &i );
    
    free(work);
    free(iwork);
    if (i == 0)
    {
        *s = S;
        *u = U;
        *vt = Vt;
    }
    else
    {
        free(S);
        free(U);
        free(Vt);
        @throw [NSException exceptionWithName:@"YCMatrixException"
                                       reason:@"Error while performing SVD."
                                     userInfo:nil];
    }
}

static void pInv(double *A, int rows, int columns, double *Aplus)
/*

Compute the pseudo inverse of matrix A

Author:  Luke Lonergan
Date:    5/31/08
License: Use pfreely

We use the approach from here:
http://en.wikipedia.org/wiki/Moore-Penrose_pseudoinverse#Finding_the_\
pseudoinverse_of_a_matrix

Synopsis:
A computationally simpler and more accurate way to get the pseudoinverse
is by using the singular value decomposition.[1][5][6] If A = U Σ V* is
the singular value decomposition of A, then A+ = V Σ+ U* . For a diagonal
matrix such as Σ, we get the pseudoinverse by taking the reciprocal of
each non-zero element on the diagonal, and leaving the zeros in place.
In numerical computation, only elements larger than some small tolerance
are taken to be nonzero, and the others are replaced by zeros. For
example, in the Matlab function pinv, the tolerance is taken to be
t = ε•max(rows,columns)•max(Σ), where ε is the machine epsilon.

Input:  the matrix A with "rows" rows and "columns" columns, in column
values consecutive order (row-major)
Output: the matrix A+ with "columns" rows and "rows" columns, the
Moore-Penrose pseudo inverse of A

The approach is summarized:
- Compute the SVD (diagonalization) of A, yielding the U, S and V
factors of A
- Compute the pseudo inverse A+ = U x S+ x Vt

S+ is the pseudo inverse of the diagonal matrix S, which is gained by
inverting the non zero diagonals

Vt is the transpose of V

Note that there is some fancy index rework in this implementation to deal
with the row values consecutive order used by the FORTRAN dgesdd_ routine.
 
*/
{
    long int    minmn;
    int    i, j, k, ii;
    double      epsilon, tolerance, maxeigen;
    double     *S = NULL, *U = NULL, *Vt = NULL;
    double     *Splus, *Splus_times_Ut;
    double *Atrans;
    
    /*
     * Calculate the tolerance for "zero" values in the SVD
     *    t = ε•max(rows,columns)•max(Σ)
     *  (Need to multiply tolerance by max of the eigenvalues when they're
     *   available)
     */
    epsilon = pow(2,1-56);
    tolerance = epsilon * MAX(rows,columns);
    maxeigen=-1.;
    
    /*
     * Here we transpose A for entry into the FORTRAN dgesdd_ routine in row
     * order. Note that dgesdd_ is destructive to the entry array, so we'd
     * need to make this copy anyway.
     */
    Atrans = (double *) malloc(sizeof(double)*columns*rows);
    for ( j = 0; j < rows; j++ ) {
        for ( i = 0; i < columns; i++ ) {
            Atrans[j+i*rows] = A[i+j*columns];
        }
    }
    
    SVDColumnMajor(Atrans, rows, columns, &S, &U, &Vt);
    
    free(Atrans);
    
    /* Use the max of the eigenvalues to normalize the zero tolerance */
    minmn = MIN(rows,columns); // The dimensions of S are min(rows,columns)
    for ( i = 0; i < minmn; i++ ) {
        maxeigen = MAX(maxeigen,S[i]);
    }
    tolerance *= maxeigen;
    
    /* Working matrices for the pseudo inverse calculation: */
    /*  1) The pseudo inverse of S: S+ */
    Splus = (double *) malloc(sizeof(double)*columns*rows);
    /*  2) An intermediate result: S+ Ut */
    Splus_times_Ut = (double *) malloc(sizeof(double)*columns*rows);
    
    
    /*
     * Calculate the pseudo inverse of the eigenvalue matrix, Splus
     * Use a tolerance to evaluate elements that are close to zero
     */
    for ( j = 0; j < rows; j++ ) {
        for ( i = 0; i < columns; i++ ) {
            if (minmn == columns) {
                ii = i;
            } else {
                ii = j;
            }
            if ( i == j && S[ii] > tolerance ) {
                Splus[i+j*columns] = 1.0 / S[ii];
            } else {
                Splus[i+j*columns] = 0.0;
            }
        }
    }
    
    for ( i = 0; i < columns; i++ ) {
        for ( j = 0; j < rows; j++ ) {
            Splus_times_Ut[i+j*columns] = 0.0;
            for ( k = 0; k < rows; k++ ) {
                Splus_times_Ut[i+j*columns] =
                Splus_times_Ut[i+j*columns] +
                Splus[i+k*columns] * U[j+k*rows];
            }
        }
    }
    
    for ( i = 0; i < columns; i++ ) {
        for ( j = 0; j < rows; j++ ) {
            Aplus[j+i*rows] = 0.0;
            for ( k = 0; k < columns; k++ ) {
                Aplus[j+i*rows] =
                Aplus[j+i*rows] +
                Vt[k+i*columns] * Splus_times_Ut[k+j*columns];
            }
        }
    }
    
    free(Splus);
    free(Splus_times_Ut);
    free(U);
    free(Vt);
    free(S);
    
    return;
}
