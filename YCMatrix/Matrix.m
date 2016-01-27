//
// Matrix.m
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

#import "Matrix.h"
#import "Constants.h"

@implementation Matrix

#pragma mark Factory Methods

+ (instancetype)matrixOfRows:(int)m columns:(int)n
{
    return [self matrixOfRows:m columns:n valuesInDiagonal:nil value:0];
}

+ (instancetype)matrixLike:(Matrix *)other
{
    return [self matrixOfRows:other->rows columns:other->columns];
}

+ (instancetype)onesLike:(Matrix *)other
{
    return [self matrixOfRows:other->rows columns:other->columns value:1.0];
}

+ (instancetype)dirtyMatrixOfRows:(int)m columns:(int)n
{
    double *new_m = malloc(m*n * sizeof(double));
	Matrix *mt = [self matrixFromArray:new_m rows:m columns:n mode:YCMWeak];
    mt->freeData = YES;
    return mt;
}

+ (instancetype)matrixOfRows:(int)m columns:(int)n value:(double)val
{
	return [self matrixOfRows:m columns:n valuesInDiagonal:nil value:val];
}

+ (instancetype)matrixOfRows:(int)m
                     columns:(int)n
             valueInDiagonal:(double)diagonal
                       value:(double)val
{
    double *new_m = malloc(m*n*sizeof(double));
    Matrix *mt = [self matrixFromArray:new_m rows:m columns:n mode:YCMWeak];
    mt->freeData = YES;
    int len = m*n;
    for (int i=0; i<len; i++)
    {
        mt->matrix[i] = val;
    }
    int mind = MIN(m, n);
    for (int i=0; i<mind; i++)
    {
        mt->matrix[i*(n+1)] = diagonal;
    }
    return mt;
}

+ (instancetype)matrixOfRows:(int)m
                     columns:(int)n
            valuesInDiagonal:(double *)diagonal
                       value:(double)val
{
	double *new_m = malloc(m*n*sizeof(double));
	Matrix *mt = [self matrixFromArray:new_m rows:m columns:n mode:YCMWeak];
    mt->freeData = YES;
	int len = m*n;
	for (int i=0; i<len; i++)
	{
		mt->matrix[i] = val;
	}
    if (diagonal)
    {
        int mind = MIN(m, n);
        for (int i=0; i<mind; i++)
        {
            mt->matrix[i*(n+1)] = diagonal[i];
        }
    }
	return mt;
}

+ (instancetype)matrixFromArray:(double *)arr rows:(int)m columns:(int)n
{
	return [self matrixFromArray:arr rows:m columns:n mode:YCMCopy];
}

+ (instancetype)matrixFromArray:(double *)arr rows:(int)m columns:(int)n mode:(refMode)mode
{
	Matrix *mt = [[Matrix alloc] init];
	if (mode == YCMCopy)
	{
		double *new_m = malloc(m*n*sizeof(double));
		memcpy(new_m, arr, m*n*sizeof(double));
		mt->matrix = new_m;
        mt->freeData = YES;
	}
	else
	{
		mt->matrix = arr;
        mt->freeData = NO;
	}
    if (mode != YCMWeak) mt->freeData = YES;
	mt->rows = m;
	mt->columns = n;
	return mt;
}

+ (instancetype)matrixFromNSArray:(NSArray *)arr rows:(int)m columns:(int)n
{
	if([arr count] != m*n)
		@throw [NSException exceptionWithName:@"MatrixSizeException"
		        reason:@"Matrix size does not match that of the input array."
		        userInfo:nil];
	Matrix *newMatrix = [Matrix matrixOfRows:m columns:n];
	double *cArray = newMatrix->matrix;
	NSUInteger j=[arr count];
	for (int i=0; i<j; i++)
	{
		cArray[i] = [[arr objectAtIndex:i] doubleValue];
	}
	return newMatrix;
}

+ (instancetype)matrixFromMatrix:(Matrix *)other
{
	Matrix *mt = [Matrix matrixFromArray:other->matrix rows:other->rows columns:other->columns];
	return mt;
}

+ (instancetype)identityOfRows:(int)m columns:(int)n
{
	double *new_m = calloc(m*n, sizeof(double));
	int minsize = m;
	if (n < m) minsize = n;
	for(int i=0; i<minsize; i++) {
		new_m[(n + 1)*i] = 1.0;
	}
	return [Matrix matrixFromArray:new_m rows:m columns:n];
}

#pragma mark Instance Methods

- (double)valueAtRow:(int)row column:(int)column
{
	[self checkBoundsForRow:row column:column];
	return matrix[row*columns + column];
}

- (double)i:(int)i j:(int)j
{
	[self checkBoundsForRow:i column:j];
	return matrix[i*columns + j];
}

- (void)setValue:(double)value row:(int)row column:(int)column
{
	[self checkBoundsForRow:row column:column];
	matrix[row*columns + column] = value;
}

- (void)i:(int)i j:(int)j set:(double)value
{
	[self checkBoundsForRow:i column:j];
	matrix[i*columns + j] = value;
}

- (void)i:(int)i j:(int)j increment:(double)value
{
    [self checkBoundsForRow:i column:j];
    matrix[i*columns + j] += value;
}

- (void)incrementAll:(double)value
{
    for (int i=0, j=(int)self.count; i<j; i++)
    {
        matrix[i] += value;
    }
}

- (void)checkBoundsForRow:(int)row column:(int)column
{
	if(column >= columns)
		@throw [NSException exceptionWithName:@"IndexOutOfBoundsException"
		        reason:@"Column index input is out of bounds."
		        userInfo:nil];
	if(row >= rows)
		@throw [NSException exceptionWithName:@"IndexOutOfBoundsException"
		        reason:@"Rows index input is out of bounds."
		        userInfo:nil];
}

- (void)checkSquare
{
    if(columns != rows)
		@throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix is not square."
                                     userInfo:nil];
}

- (Matrix *)matrixByAdding:(Matrix *)addend
{
	return [self matrixByMultiplyingWithScalar:1 AndAdding:addend];
}

- (Matrix *)matrixBySubtracting:(Matrix *)subtrahend
{
	return [subtrahend matrixByMultiplyingWithScalar:-1 AndAdding:self];
}

- (Matrix *)matrixByMultiplyingWithRight:(Matrix *)mt
{
	return [self matrixByTransposing:NO
	        TransposingRight:NO
	        MultiplyWithRight:mt
	        Factor:1
	        Adding:nil];
}

- (Matrix *)matrixByMultiplyingWithRight:(Matrix *)mt AndTransposing:(bool)trans
{
	Matrix *M1 = trans ? mt : self;
	Matrix *M2 = trans ? self : mt;
	return [M1 matrixByTransposing:trans
	        TransposingRight:trans
	        MultiplyWithRight:M2
	        Factor:1
	        Adding:nil];
}

- (Matrix *)matrixByMultiplyingWithRight:(Matrix *)mt AndAdding:(Matrix *)ma
{
	return [self matrixByTransposing:NO
	        TransposingRight:NO
	        MultiplyWithRight:mt
	        Factor:1
	        Adding:ma];
}

- (Matrix *)matrixByMultiplyingWithRight:(Matrix *)mt AndFactor:(double)sf
{
	return [self matrixByTransposing:NO
	        TransposingRight:NO
	        MultiplyWithRight:mt
	        Factor:sf
	        Adding:nil];
}

- (Matrix *)matrixByTransposingAndMultiplyingWithRight:(Matrix *)mt
{
	return [self matrixByTransposing:YES
	        TransposingRight:NO
	        MultiplyWithRight:mt
	        Factor:1
	        Adding:nil];
}

- (Matrix *)matrixByTransposingAndMultiplyingWithLeft:(Matrix *)mt
{
	return [mt matrixByTransposing:NO
	        TransposingRight:YES
	        MultiplyWithRight:self
	        Factor:1
	        Adding:nil];
}

//
// Actual calls to BLAS

- (Matrix *)matrixByTransposing:(BOOL)transposeLeft
        TransposingRight:(BOOL)transposeRight
        MultiplyWithRight:(Matrix *)mt
        Factor:(double)factor
        Adding:(Matrix *)addend
{
	int M = transposeLeft ? columns : rows;
	int N = transposeRight ? mt->rows : mt->columns;
	int K = transposeLeft ? rows : columns;
	int lda = columns;
	int ldb = mt->columns;
	int ldc = N;

	if ((transposeLeft ? rows : columns) != (transposeRight ? mt->columns : mt->rows))
	{
		@throw [NSException exceptionWithName:@"MatrixSizeException"
		        reason:@"Matrix size unsuitable for multiplication."
		        userInfo:nil];
	}
	if (addend && (addend->rows != M && addend->columns != N)) // FIX!!!
	{
		@throw [NSException exceptionWithName:@"MatrixSizeException"
		        reason:@"Matrix size unsuitable for addition."
		        userInfo:nil];
	}
	enum CBLAS_TRANSPOSE lT = transposeLeft ? CblasTrans : CblasNoTrans;
	enum CBLAS_TRANSPOSE rT = transposeRight ? CblasTrans : CblasNoTrans;

	Matrix *result = addend ?[Matrix matrixFromMatrix:addend] :[Matrix matrixOfRows:M
	                                                                columns:N];
	cblas_dgemm(CblasRowMajor, lT,          rT,         M,
	            N,              K,          factor,     matrix,
	            lda,            mt->matrix, ldb,        1,
	            result->matrix, ldc);
	return result;
}

- (Matrix *)matrixByMultiplyingWithScalar:(double)ms
{
	Matrix *product = [Matrix matrixFromMatrix:self];
	cblas_dscal(rows*columns, ms, product->matrix, 1);
	return product;
}

- (Matrix *)matrixByMultiplyingWithScalar:(double)ms AndAdding:(Matrix *)addend
{
	if(columns != addend->columns || rows != addend->rows || sizeof(matrix) != sizeof(addend->matrix))
		@throw [NSException exceptionWithName:@"MatrixSizeException"
		        reason:@"Matrix size mismatch."
		        userInfo:nil];
	Matrix *sum = [Matrix matrixFromMatrix:addend];
	cblas_daxpy(rows*columns, ms, self->matrix, 1, sum->matrix, 1);
	return sum;
}

// End of actual calls to BLAS
//

- (Matrix *)matrixByNegating
{
	return [self matrixByMultiplyingWithScalar:-1];
}

- (Matrix *)matrixBySquaring
{
    Matrix *result = [Matrix matrixLike:self];
    vDSP_vsqD(self->matrix, 1, result->matrix, 1, self.count);
    return result;
}

- (Matrix *)matrixByTransposing
{
	Matrix *trans = [Matrix dirtyMatrixOfRows:columns columns:rows];
	vDSP_mtransD(self->matrix, 1, trans->matrix, 1, trans->rows, trans->columns);
	return trans;
}

- (Matrix *)matrixByElementWiseMultiplyWith:(Matrix *)mt
{
	Matrix *result = [self copy];
	[result elementWiseMultiply:mt];
	return result;
}

- (Matrix *)matrixByElementWisDivideBy:(Matrix *)mt
{
    Matrix *result = [self copy];
    [result elementWiseDivide:mt];
    return result;
}

- (void)add:(Matrix *)addend
{
	if(columns != addend->columns || rows != addend->rows)
		@throw [NSException exceptionWithName:@"MatrixSizeException"
		        reason:@"Matrix size mismatch."
		        userInfo:nil];
	cblas_daxpy(rows*columns, 1, addend->matrix, 1, self->matrix, 1);
}

- (void)subtract:(Matrix *)subtrahend
{
	if(columns != subtrahend->columns || rows != subtrahend->rows)
		@throw [NSException exceptionWithName:@"MatrixSizeException"
		        reason:@"Matrix size mismatch."
		        userInfo:nil];
	cblas_daxpy(rows*columns, -1, subtrahend->matrix, 1, self->matrix, 1);
}

- (void)multiplyWithScalar:(double)ms
{
	cblas_dscal(rows*columns, ms, matrix, 1);
}

- (void)negate
{
	[self multiplyWithScalar:-1];
}

- (void)square
{
    vDSP_vsqD(self->matrix, 1, self->matrix, 1, self.count);
}

- (void)elementWiseMultiply:(Matrix *)mt
{
	if(columns != mt->columns || rows != mt->rows)
		@throw [NSException exceptionWithName:@"MatrixSizeException"
		        reason:@"Matrix size mismatch."
		        userInfo:nil];
	for (int i=0, j=self->rows * self->columns; i<j; i++)
	{
		self->matrix[i] *= mt->matrix[i];
	}
}

- (void)elementWiseDivide:(Matrix *)mt
{
    if(columns != mt->columns || rows != mt->rows)
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    for (int i=0, j=self->rows * self->columns; i<j; i++)
    {
        self->matrix[i] /= mt->matrix[i];
    }
}

- (double)trace
{
	[self checkSquare];
	double trace = 0;
	for (int i=0; i<rows; i++)
	{
		trace += matrix[i*(columns + 1)];
	}
	return trace;
}

- (double)dotWith:(Matrix *)other
{
	// A few more checks need to be made here.
	if(columns != 1 && rows != 1)
		@throw [NSException exceptionWithName:@"MatrixSizeException"
		        reason:@"Dot can only be performed on vectors."
		        userInfo:nil];
	return cblas_ddot(self->rows * self->columns, self->matrix, 1, other->matrix, 1);
}

- (Matrix *)matrixByUnitizing
{
	if(columns != 1 && rows != 1)
		@throw [NSException exceptionWithName:@"MatrixSizeException"
		        reason:@"Unit can only be performed on vectors."
		        userInfo:nil];
	int len = rows * columns;
	double sqsum = 0;
	for (int i=0; i<len; i++)
	{
		double v = matrix[i];
		sqsum += v*v;
	}
	double invmag = 1/sqrt(sqsum);
	Matrix *norm = [Matrix matrixOfRows:rows columns:columns];
	double *normMatrix = norm->matrix;
	for (int i=0; i<len; i++)
	{
		normMatrix[i] = matrix[i] * invmag;
	}
	return norm;
}

- (double *)array
{
	return matrix;
}

- (double *)arrayCopy
{
	double *resArr = calloc(self->rows*self->columns, sizeof(double));
	memcpy(resArr, matrix, self->rows*self->columns*sizeof(double));
	return resArr;
}

- (NSArray *)numberArray
{
	int length = self->rows * self->columns;
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:length];
	for (int i=0; i<length; i++)
	{
		[result addObject:@(self->matrix[i])];
	}
	return result;
}

- (Matrix *)diagonal
{
    int minDim = MIN(rows, columns);
    Matrix *result = [Matrix matrixOfRows:minDim columns:1];
    for (int i=0; i<minDim; i++)
    {
        [result setValue:[self valueAtRow:i column:i] row:i column:0];
    }
    return result;
}

- (int)rows
{
	return self->rows;
}

- (int)columns
{
	return self->columns;
}

- (NSUInteger)count
{
	return self->rows * self->columns;
}

- (double)sum
{
	double sum = 0;
    NSUInteger j= [self count];
	for (int i=0; i<j; i++)
	{
		sum += self->matrix[i];
	}
	return sum;
}

- (double)product
{
    double product = 1;
    NSUInteger j= [self count];
    for (int i=0; i<j; i++)
    {
        product *= self->matrix[i];
    }
    return product;
}

- (double)min
{
    double min = DBL_MAX;
    NSUInteger j= [self count];
    for (int i=0; i<j; i++)
    {
        if (self->matrix[i] < min) min = self->matrix[i];
    }
    return min;
}

- (double)max
{
    double max = -DBL_MAX;
    NSUInteger j= [self count];
    for (int i=0; i<j; i++)
    {
        if (self->matrix[i] > max) max = self->matrix[i];
    }
    return max;
}

- (BOOL)isSquareMatrix
{
	return self->rows == self->columns;
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[self class]]) return NO;
	Matrix *other = (Matrix *)anObject;
	if (rows != other->rows || columns != other->columns) return NO;
	int arr_length = self->rows * self->columns;
	for (int i=0; i<arr_length; i++) {
		if (matrix[i] != other->matrix[i]) return NO;
	}
	return YES;
}

- (BOOL)isEqualToMatrix:(Matrix *)aMatrix tolerance:(double)tolerance
{
    if (self->rows != aMatrix->rows || self->columns != aMatrix->columns) return NO;
    int arr_length = self->rows * self->columns;
    for (int i=0; i<arr_length; i++)
    {
        double diff = ABS(matrix[i] - aMatrix->matrix[i]);
		if (  diff > tolerance ) return NO;
	}
    return YES;
}

- (NSString *)description {
	NSString *s = @"\n";
	for ( int i=0; i<rows*columns; ++i ) {
		s = [NSString stringWithFormat:@"%@\t%f", s, matrix[i]];
		if (i % columns == columns - 1) s = [NSString stringWithFormat:@"%@\n", s];
	}
	return s;
}

#pragma mark Object Destruction

- (void)dealloc {
	if (self->freeData) free(self->matrix);
}

#pragma mark NSCoding Implementation

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeBytes:(const uint8_t *)self->matrix
                  length:self.count * sizeof(double)
                  forKey:@"matrix"];
	[encoder encodeInt:self->rows forKey:@"rows"];
    [encoder encodeInt:self->columns forKey:@"columns"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	if (self = [super init])
	{
        self->freeData = YES;
		self->rows = [decoder decodeIntForKey:@"rows"];
		self->columns = [decoder decodeIntForKey:@"columns"];
        if ([decoder containsValueForKey:@"matrix"])
        {
            NSUInteger length;
            double *tempMatrix = (double *)[decoder decodeBytesForKey:@"matrix" returnedLength:&length];
            NSAssert(length == self.count * sizeof(double), @"Decoded matrix length differs");
            self->matrix = malloc(length);
            memcpy(self->matrix, tempMatrix, length);
        }
        else
        {
            // legacy decoding
            NSArray *matrixContent = [decoder decodeObjectForKey:@"matrixContent"];
            int len = self->rows*self->columns;
            self->matrix = malloc(len*sizeof(double));
            for (int i=0; i<len; i++)
            {
                self->matrix[i] = [matrixContent[i] doubleValue];
            }
        }
	}
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	Matrix *newMatrix = [Matrix matrixFromArray:self->matrix
	                       rows:self->rows
	                       columns:self->columns];
	return newMatrix;
}

@end
