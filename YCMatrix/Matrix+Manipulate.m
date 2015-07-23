//
// Matrix+Manipulate.m
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

#import "Matrix+Manipulate.h"
#import "Constants.h"

@implementation Matrix (Manipulate)

+ (Matrix *)matrixFromRows:(NSArray *)rows
{
    NSUInteger rowCount = [rows count];
    if (rowCount == 0) return [Matrix matrixOfRows:0 Columns:0];
    Matrix *firstRow = rows[0];
    int columnCount = firstRow->columns;
    Matrix *ret = [Matrix matrixOfRows:(int)rowCount Columns:(int)columnCount];
    for (int i=0; i<rowCount; i++)
    {
        Matrix *currentRow = rows[i];
        for (int j=0; j<columnCount; j++)
        {
            [ret setValue:currentRow->matrix[j] Row:i Column:j];
        }
    }
    return ret;
}

+ (Matrix *)matrixFromColumns:(NSArray *)columns
{
    NSUInteger columnCount = [columns count];
    if (columnCount == 0) return [Matrix matrixOfRows:0 Columns:0];
    Matrix *firstCol = columns[0];
    int rowCount = firstCol->rows;
    Matrix *ret = [Matrix matrixOfRows:(int)rowCount Columns:(int)columnCount];
    for (int i=0; i<columnCount; i++)
    {
        Matrix *currentCol = columns[i];
        for (int j=0; j<rowCount; j++)
        {
            [ret setValue:currentCol->matrix[j] Row:j Column:i];
        }
    }
    return ret;
}

- (void)copyValuesFrom:(Matrix *)aMatrix
{
    NSAssert(aMatrix.rows == self.rows && aMatrix.columns == self.columns, @"Incorrect matrix size");
    memcpy(self->matrix, aMatrix->matrix, self.rows * self.columns * sizeof(double));
}

- (Matrix *)row:(int) rowIndex
{
    if (rowIndex > self->rows - 1)
    {
        @throw [NSException exceptionWithName:@"IndexOutOfBoundsException"
                                       reason:@"Row index input is out of bounds."
                                     userInfo:nil];
    }
    // http://stackoverflow.com/questions/5850000/how-to-split-array-into-two-arrays-in-c
    int startIndex = rowIndex * self->columns;
    Matrix *rowmatrix = [Matrix matrixOfRows:1 Columns:self->columns];
    double *row = rowmatrix->matrix;
    memcpy(row, self->matrix + startIndex, self->columns * sizeof(double));
    return rowmatrix;
}

- (Matrix *)rows:(NSIndexSet *)indexes
{
    // TODO: Speed up retrieval of rows
    __block Matrix *result;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (result)
        {
            result = [result appendRow:[self row:(int)idx]];
        }
        else
        {
            result = [self row:(int)idx];
        }
    }];
    return result;
}

- (void)setRow:(int)rowIndex Value:(Matrix *)rowValue
{
    if (rowIndex > self->rows - 1)
    {
        @throw [NSException exceptionWithName:@"IndexOutOfBoundsException"
                                       reason:@"Row index input is out of bounds."
                                     userInfo:nil];
    }
    if (rowValue->rows != 1 || rowValue->columns != columns)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    memcpy(self->matrix + columns * rowIndex, rowValue->matrix, columns * sizeof(double));
}

- (NSArray *)rowsAsNSArray
{
    NSMutableArray *rowsArray = [NSMutableArray arrayWithCapacity:rows];
    for (int i=0; i<rows; i++)
    {
        [rowsArray addObject: [self row:i]];
    }
    return rowsArray;
}

- (Matrix *)column:(int) colIndex
{
    if (colIndex > self->columns - 1)
    {
        @throw [NSException exceptionWithName:@"IndexOutOfBoundsException"
                                       reason:@"Column index input is out of bounds."
                                     userInfo:nil];
    }
    Matrix *columnmatrix = [Matrix matrixOfRows:self->rows Columns:1];
    double *column = columnmatrix->matrix;
    for (int i=0; i<self->rows; i++)
    {
        column[i] = self->matrix[i*self->columns + colIndex];
    }
    return columnmatrix;
}

- (Matrix *)columns:(NSIndexSet *)indexes
{
    // TODO: Speed up retrieval of columns
    __block Matrix *result;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (result)
        {
            result = [result appendColumn:[self column:(int)idx]];
        }
        else
        {
            result = [self column:(int)idx];
        }
    }];
    return result;
}

- (void)setColumn:(int)colNumber Value:(Matrix *)columnValue
{
    if (colNumber > self->columns - 1)
    {
        @throw [NSException exceptionWithName:@"IndexOutOfBoundsException"
                                       reason:@"Column index input is out of bounds."
                                     userInfo:nil];
    }
    if (columnValue->columns != 1 || columnValue->rows != rows)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    for (int i=0; i<rows; i++)
    {
        self->matrix[columns*i + colNumber] = columnValue->matrix[i];
    }
}

- (NSArray *)columnsAsNSArray // needs some speed improvement
{
    NSMutableArray *columnsArray = [NSMutableArray arrayWithCapacity:columns];
    for (int i=0; i<columns; i++)
    {
        [columnsArray addObject: [self column:i]];
    }
    return columnsArray;
}

- (Matrix *)matrixByAddingRow:(Matrix *)row
{
    Matrix *result = [self copy];
    [result addRow:row];
    return result;
}

- (Matrix *)matrixBySubtractingRow:(Matrix *)row
{
    Matrix *result = [self copy];
    [result subtractRow:row];
    return result;
}

- (Matrix *)matrixByMultiplyingWithRow:(Matrix *)row
{
    Matrix *result = [self copy];
    [result multiplyRow:row];
    return result;
}

- (Matrix *)matrixByAddingColumn:(Matrix *)column
{
    Matrix *result = [self copy];
    [result addColumn:column];
    return result;
}

- (Matrix *)matrixBySubtractingColumn:(Matrix *)column
{
    Matrix *result = [self copy];
    [result subtractColumn:column];
    return result;
}

- (Matrix *)matrixByMultiplyingWithColumn:(Matrix *)column
{
    Matrix *result = [self copy];
    [result multiplyColumn:column];
    return result;
}

- (Matrix *)matrixWithRowsInRange:(NSRange)range
{
    if (range.location + range.length > self->rows)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Range outside matrix."
                                     userInfo:nil];
    }
    int valueOffset = (int)range.location * self->columns;
    int valueCount = (int)range.length * self->columns;
    
    Matrix *newMatrix = [Matrix matrixOfRows:(int)range.length Columns:self->columns];
    memcpy(newMatrix->matrix, self->matrix+valueOffset, valueCount * sizeof(double));
    
    return newMatrix;
}

- (Matrix *)matrixWithColumnsInRange:(NSRange)range
{
    if (range.location + range.length > self->columns)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Range outside matrix."
                                     userInfo:nil];
    }
    int rowOffset = (int)range.location;
    int rowLength = (int)range.length;
    
    Matrix *newMatrix = [Matrix matrixOfRows:self->rows Columns:rowLength];
    
    for (int i=0; i<self->rows; i++)
    {
        memcpy(newMatrix->matrix + i*rowLength,
               self->matrix + rowOffset + i*self->columns,
               rowLength * sizeof(double));
    }
    return newMatrix;
}

- (void)addRow:(Matrix *)row
{
    if (row->rows != 1 || row->columns != self->columns)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    double *sumarray = self->matrix;
    double *addendarray = row->matrix;
    int cols = self->columns;
    int rws = self->rows;
    for (int i=0; i<rws; i++)
    {
        for (int j=0; j<cols; j++)
        {
            sumarray[i*cols + j] += addendarray[j]; //j!
        }
    }
}

- (void)subtractRow:(Matrix *)row
{
    if (row->rows != 1 || row->columns != self->columns)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    double *subtractedarray = self->matrix;
    double *subtrahendarray = row->matrix;
    int cols = self->columns;
    int rws = self->rows;
    for (int i=0; i<rws; i++)
    {
        for (int j=0; j<cols; j++)
        {
            subtractedarray[i*cols + j] -= subtrahendarray[j]; //j!
        }
    }
}

- (void)multiplyRow:(Matrix *)row
{
    if (row->rows != 1 || row->columns != self->columns)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    double *productarray = self->matrix;
    double *factorarray = row->matrix;
    int cols = self->columns;
    int rws = self->rows;
    for (int i=0; i<rws; i++)
    {
        for (int j=0; j<cols; j++)
        {
            productarray[i*cols + j] *= factorarray[j]; //j!
        }
    }
}

- (void)addColumn:(Matrix *)column
{
    if (column->columns != 1 || column->rows != self->rows)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    double *sumarray = self->matrix;
    double *addendarray = column->matrix;
    int cols = self->columns;
    int rws = self->rows;
    for (int i=0; i<rws; i++)
    {
        for (int j=0; j<cols; j++)
        {
            sumarray[i*cols + j] += addendarray[i]; //i!
        }
    }
}

- (void)subtractColumn:(Matrix *)column
{
    if (column->columns != 1 || column->rows != self->rows)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    double *subtractedarray = self->matrix;
    double *subtrahendarray = column->matrix;
    int cols = self->columns;
    int rws = self->rows;
    for (int i=0; i<rws; i++)
    {
        for (int j=0; j<cols; j++)
        {
            subtractedarray[i*cols + j] -= subtrahendarray[i]; //i!
        }
    }
}

- (void)multiplyColumn:(Matrix *)column
{
    if (column->columns != 1 || column->rows != self->rows)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    double *productarray = self->matrix;
    double *factorarray = column->matrix;
    int cols = self->columns;
    int rws = self->rows;
    for (int i=0; i<rws; i++)
    {
        for (int j=0; j<cols; j++)
        {
            productarray[i*cols + j] *= factorarray[i]; //i!
        }
    }
}

- (Matrix *)appendRow:(Matrix *)newRow
{
    if (newRow->rows != 1 || newRow->columns != columns)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    double *newMatrix = malloc(columns * (rows + 1) * sizeof(double));
    memcpy(newMatrix, self->matrix, columns * rows * sizeof(double));
    memcpy(newMatrix + columns*rows, newRow->matrix, columns * sizeof(double));
    return [Matrix matrixFromArray:newMatrix Rows:rows + 1 Columns:columns Mode:YCMStrong];
}

- (Matrix *)appendColumn:(Matrix *)newColumn
{
    if (newColumn->columns != 1 || newColumn->rows != rows)
    {
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"Matrix size mismatch."
                                     userInfo:nil];
    }
    double *newMatrix = malloc((columns + 1) * rows * sizeof(double));
    int newCols = columns + 1;
    for (int i=0; i < rows; i++)
    {
        memcpy(newMatrix + newCols * i, self->matrix + columns * i, columns * sizeof(double));
        newMatrix[newCols * i + columns] = newColumn->matrix[i];
    }
    return [Matrix matrixFromArray:newMatrix Rows:rows Columns:columns + 1 Mode:YCMStrong];
}

- (Matrix *)removeRow:(int)rowNumber
{
    double newRows = rows - 1;
    if (rowNumber > newRows)
    {
        @throw [NSException exceptionWithName:@"IndexOutOfBoundsException"
                                       reason:@"Row index input is out of bounds."
                                     userInfo:nil];
    }
    double *newMatrix = malloc(columns * newRows * sizeof(double));
    for (int i=0; i < newRows; i++) // should count to one-less than rows, so newRows
    {
        int idx = i >= rowNumber ? i+1 : i;
        memcpy(newMatrix + columns * i, self->matrix + columns * idx, columns * sizeof(double));
    }
    return [Matrix matrixFromArray:newMatrix Rows:newRows Columns:columns];
}

- (Matrix *)removeColumn:(int)columnNumber
{
    if (columnNumber > self->columns - 1)
    {
        @throw [NSException exceptionWithName:@"IndexOutOfBoundsException"
                                       reason:@"Column index input is out of bounds."
                                     userInfo:nil];
    }
    int newCols = columns - 1;
    double *newMatrix = malloc(newCols * rows * sizeof(double));
    for (int i=0; i < rows; i++)
    {
        memcpy(newMatrix + i*newCols,
               self->matrix + i*self->columns,
               columnNumber * sizeof(double));
        memcpy(newMatrix + columnNumber + i*newCols,
               self->matrix + columnNumber + 1  + i*self->columns,
               (newCols - columnNumber) * sizeof(double));
    }
    return [Matrix matrixFromArray:newMatrix Rows:rows Columns:newCols];
}

- (Matrix *)appendValueAsRow:(double)value
{
    if(columns != 1)
        @throw [NSException exceptionWithName:@"MatrixSizeException"
                                       reason:@"appendValueAsRow can only be performed on vectors."
                                     userInfo:nil];
    int newRows = rows + 1;
    double *newArray = malloc(columns * newRows * sizeof(double));
    memcpy(newArray, matrix, columns * rows * sizeof(double));
    newArray[columns * newRows - 1] = value;
    return [Matrix matrixFromArray:newArray Rows:newRows Columns:columns];
}

// Fisher-Yates Inside-out Shuffle (UNTESTED!)
- (Matrix *)matrixByShufflingRows
{
    Matrix *ret = [Matrix matrixFromMatrix:self];
    int rowCount = self->rows;
    int colCount = self->columns;
    for (int i=0; i<rowCount; i++)
    {
        int o = arc4random_uniform((int)i);
        if (o == i) continue;
        for (int j=0; j<colCount; j++)
        {
            ret->matrix[i*rowCount + j] = ret->matrix[o*rowCount + j];
            ret->matrix[o*rowCount + j] = self->matrix[o*rowCount + j];
        }
    }
    return ret;
}

// Fisher-Yates Shuffle (UNTESTED!)
- (void)shuffleRows
{
    int rowCount = self->rows;
    int colCount = self->columns;
    double tmp;
    for (int i = rowCount - 1; i>=0; --i)
    {
        int o = arc4random_uniform((int)i);
        for (int j=0; j<colCount; j++)
        {
            tmp = self->matrix[i*rowCount + j];
            self->matrix[i*rowCount + j] = self->matrix[o*rowCount + j];
            self->matrix[o*rowCount + j] = tmp;
        }
    }
}

// Fisher-Yates Inside-out Shuffle (UNTESTED!)
- (Matrix *)matrixByShufflingColumns
{
    Matrix *ret = [Matrix matrixFromMatrix:self];
    int rowCount = self->rows;
    int colCount = self->columns;
    for (int i=0; i<colCount; i++)
    {
        int o = arc4random_uniform((int)i);
        for (int j=0; j<colCount; j++)
        {
            ret->matrix[j*rowCount + i] = ret->matrix[j*rowCount + o];
            ret->matrix[j*rowCount + o] = self->matrix[j*rowCount + o];
        }
    }
    return ret;
}

// Fisher-Yates Shuffle (UNTESTED!)
- (void)shuffleColumns
{
    int rowCount = self->rows;
    int colCount = self->columns;
    double tmp;
    for (int i = colCount - 1; i>=0; --i)
    {
        int o = arc4random_uniform((int)i);
        for (int j=0; j<rowCount; j++)
        {
            tmp = self->matrix[j*rowCount + i];
            self->matrix[j*rowCount + i] = self->matrix[j*rowCount + o];
            self->matrix[j*rowCount + o] = tmp;
        }
    }
}

- (Matrix *)matrixBySamplingRows:(NSUInteger)sampleCount Replacement:(BOOL)replacement
{
    int rowSize = self->rows;
    int colSize = self->columns;
    int colMemory = colSize * sizeof(double);
    Matrix *new = [Matrix matrixOfRows:(int)sampleCount Columns:colSize];
    if (replacement)
    {
        for (int i=0; i<sampleCount; i++)
        {
            int rnd = arc4random_uniform((int)self->rows);
            memcpy(new->matrix + i * colMemory, self->matrix + rnd * colMemory, colSize);
        }
    }
    else
    {
        // Knuth's S algorithm
        int i = 0;
        int n = (int)sampleCount;
        int samples = n;
        NSUInteger N = rowSize;
        while (n > 0)
        {
            if (N * (double)arc4random() / 0x1000000000 <= n)
            {
                memcpy(new->matrix + (samples - n) * colMemory, self->matrix + i * colMemory, colSize);
                n--;
            }
            i++;
            N--;
        }
    }
    return new;
}

- (Matrix *)matrixBySamplingColumns:(NSUInteger)sampleCount Replacement:(BOOL)replacement
{
    int rowSize = self->rows;
    int colSize = self->columns;
    Matrix *new = [Matrix matrixOfRows:rowSize Columns:(int)sampleCount];
    if (replacement)
    {
        for (int i=0; i<sampleCount; i++)
        {
            int rnd = arc4random_uniform((int)self->rows);
            [new setColumn:i Value:[self column:rnd]];
        }
    }
    else
    {
        // Knuth's S algorithm
        int i = 0;
        int n = (int)sampleCount;
        int samples = n;
        NSUInteger N = colSize;
        while (n > 0)
        {
            if (N * (double)arc4random() / 0x1000000000 <= n)
            {
                [new setColumn:samples - n Value:[self column:i]];
                n--;
            }
            i++;
            N--;
        }
    }
    return new;
}

@end
