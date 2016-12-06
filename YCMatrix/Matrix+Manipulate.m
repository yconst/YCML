//
// Matrix+Manipulate.m
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

#import "Matrix+Manipulate.h"
#import "Constants.h"

#define ARC4RANDOM_MAX      0x100000000

@implementation Matrix (Manipulate)

+ (Matrix *)matrixFromRows:(NSArray *)rows
{
    NSUInteger rowCount = [rows count];
    if (rowCount == 0) return [Matrix matrixOfRows:0 columns:0];
    Matrix *firstRow = rows[0];
    int columnCount = firstRow->columns;
    Matrix *ret = [Matrix matrixOfRows:(int)rowCount columns:(int)columnCount];
    for (int i=0; i<rowCount; i++)
    {
        Matrix *currentRow = rows[i];
        for (int j=0; j<columnCount; j++)
        {
            [ret setValue:currentRow->matrix[j] row:i column:j];
        }
    }
    return ret;
}

+ (Matrix *)matrixFromColumns:(NSArray *)columns
{
    NSUInteger columnCount = [columns count];
    if (columnCount == 0) return [Matrix matrixOfRows:0 columns:0];
    Matrix *firstCol = columns[0];
    int rowCount = firstCol->rows;
    Matrix *ret = [Matrix matrixOfRows:(int)rowCount columns:(int)columnCount];
    for (int i=0; i<columnCount; i++)
    {
        Matrix *currentCol = columns[i];
        for (int j=0; j<rowCount; j++)
        {
            [ret setValue:currentCol->matrix[j] row:j column:i];
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
    NSAssert(rowIndex < self->rows, @"Index out of bounds");
    // http://stackoverflow.com/questions/5850000/how-to-split-array-into-two-arrays-in-c
    int startIndex = rowIndex * self->columns;
    Matrix *rowmatrix = [Matrix matrixOfRows:1 columns:self->columns];
    double *row = rowmatrix->matrix;
    memcpy(row, self->matrix + startIndex, self->columns * sizeof(double));
    return rowmatrix;
}

- (Matrix *)rowReference:(int)rowIndex
{
    NSAssert(rowIndex < self->rows, @"Index out of bounds");
    int startIndex = rowIndex * self->columns;
    return [Matrix matrixFromArray:self->matrix+startIndex rows:1
                           columns:self->columns mode:YCMWeak];
}

- (Matrix *)rowReferenceVector:(int)rowIndex
{
    NSAssert(rowIndex < self->rows, @"Index out of bounds");
    int startIndex = rowIndex * self->columns;
    return [Matrix matrixFromArray:self->matrix+startIndex rows:self->columns
                           columns:1 mode:YCMWeak];
}

- (Matrix *)rows:(NSIndexSet *)indexes
{
    NSAssert([indexes lastIndex] < self->rows, @"Index out of bounds");
    __block int count = 0;
    Matrix *result = [Matrix matrixOfRows:(int)[indexes count] columns:self.columns];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [result setRow:count++ value:[self row:(int)idx]];
    }];
    return result;
}

- (void)setRow:(int)rowIndex value:(Matrix *)rowValue
{
    NSAssert(rowIndex < self->rows, @"Index out of bounds");
    NSAssert(rowValue->rows == 1 && rowValue->columns == columns, @"Matrix size mismatch");
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

- (NSArray *)rowWiseSplitAtIndexes:(NSIndexSet *)indexes
{
    NSAssert([indexes lastIndex] < self.rows, @"Largest index out of bounds");
    NSMutableArray *segments = [NSMutableArray array];
    __block NSUInteger lastIndex = 0;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = NSMakeRange(lastIndex, idx - lastIndex);
        Matrix *segment = [self rows:[NSIndexSet indexSetWithIndexesInRange:range]];
        [segments addObject:segment];
        lastIndex = idx;
    }];
    
    NSRange range = NSMakeRange(lastIndex, self.rows - lastIndex);
    Matrix *segment = [self rows:[NSIndexSet indexSetWithIndexesInRange:range]];
    [segments addObject:segment];
    
    return segments;
}

- (NSArray *)rowWisePartition:(int)size
{
    int remainder = self.rows % size;
    int partitions = self.rows / size;
    if (remainder > 0)
    {
        partitions++;
    }
    NSMutableArray *result = [NSMutableArray array];
    for (int i=0; i<partitions; i++)
    {
        int sLim = size;
        if (i == partitions - 1 && remainder > 0)
        {
            sLim = remainder;
        }
        NSRange partitionRange = NSMakeRange(i * size, sLim);
        Matrix *partition = [self rows:[NSIndexSet indexSetWithIndexesInRange:partitionRange]];
        [result addObject:partition];
    }
    return result;
}

- (Matrix *)column:(int) colIndex
{
    NSAssert(colIndex < self->columns, @"Index out of bounds");
    Matrix *columnmatrix = [Matrix matrixOfRows:self->rows columns:1];
    double *column = columnmatrix->matrix;
    for (int i=0; i<self->rows; i++)
    {
        column[i] = self->matrix[i*self->columns + colIndex];
    }
    return columnmatrix;
}

- (Matrix *)columns:(NSIndexSet *)indexes
{
    NSAssert([indexes lastIndex] < self->columns, @"Index out of bounds");
    __block int count = 0;
    Matrix *result = [Matrix matrixOfRows:self.rows columns:(int)[indexes count]];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [result setColumn:count++ value:[self column:(int)idx]];
    }];
    return result;
}

- (void)setColumn:(int)colIndex value:(Matrix *)columnValue
{
    NSAssert(colIndex < self->columns, @"Index out of bounds");
    NSAssert(columnValue->columns == 1 && columnValue->rows == rows, @"Matrix size mismatch");
    for (int i=0; i<rows; i++)
    {
        self->matrix[columns*i + colIndex] = columnValue->matrix[i];
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

- (NSArray *)columnWiseSplitAtIndexes:(NSIndexSet *)indexes
{
    NSAssert([indexes lastIndex] < self.columns, @"Largest index out of range");
    NSMutableArray *segments = [NSMutableArray array];
    __block NSUInteger lastIndex = 0;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = NSMakeRange(lastIndex, idx - lastIndex);
        Matrix *segment = [self columns:[NSIndexSet indexSetWithIndexesInRange:range]];
        [segments addObject:segment];
        lastIndex = idx;
    }];
    
    NSRange range = NSMakeRange(lastIndex, self.columns - lastIndex);
    Matrix *segment = [self columns:[NSIndexSet indexSetWithIndexesInRange:range]];
    [segments addObject:segment];
    
    return segments;
}

- (NSArray *)columnWisePartition:(int)size
{
    int remainder = self.columns % size;
    int partitions = self.columns / size;
    if (remainder > 0)
    {
        partitions++;
    }
    NSMutableArray *result = [NSMutableArray array];
    for (int i=0; i<partitions; i++)
    {
        int sLim = size;
        if (i == partitions - 1 && remainder > 0)
        {
            sLim = remainder;
        }
        NSRange partitionRange = NSMakeRange(i * size, sLim);
        Matrix *partition = [self columns:[NSIndexSet indexSetWithIndexesInRange:partitionRange]];
        [result addObject:partition];
    }
    return result;
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
    NSAssert(range.location + range.length <= self->rows, @"Input out of bounds");
    int valueOffset = (int)range.location * self->columns;
    int valueCount = (int)range.length * self->columns;
    
    Matrix *newMatrix = [Matrix matrixOfRows:(int)range.length columns:self->columns];
    memcpy(newMatrix->matrix, self->matrix+valueOffset, valueCount * sizeof(double));
    
    return newMatrix;
}

- (Matrix *)matrixWithColumnsInRange:(NSRange)range
{
    NSAssert(range.location + range.length <= self->columns, @"Input out of bounds");
    int rowOffset = (int)range.location;
    int rowLength = (int)range.length;
    
    Matrix *newMatrix = [Matrix matrixOfRows:self->rows columns:rowLength];
    
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
    NSAssert(row->rows == 1 && row->columns == self->columns, @"Matrix size mismatch");
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
    NSAssert(row->rows == 1 && row->columns == self->columns, @"Matrix size mismatch");
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
    NSAssert(row->rows == 1 && row->columns == self->columns, @"Matrix size mismatch");
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

- (void)divideRow:(Matrix *)row
{
    NSAssert(row->rows == 1 && row->columns == self->columns, @"Matrix size mismatch");
    double *productarray = self->matrix;
    double *factorarray = row->matrix;
    int cols = self->columns;
    int rws = self->rows;
    for (int i=0; i<rws; i++)
    {
        for (int j=0; j<cols; j++)
        {
            productarray[i*cols + j] /= factorarray[j]; //j!
        }
    }

}

- (void)addColumn:(Matrix *)column
{
    NSAssert(column->columns == 1 && column->rows == self->rows, @"Matrix size mismatch");
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
    NSAssert(column->columns == 1 && column->rows == self->rows, @"Matrix size mismatch");
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
    NSAssert(column->columns == 1 && column->rows == self->rows, @"Matrix size mismatch");
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

- (void)divideColumn:(Matrix *)column
{
    NSAssert(column->columns == 1 && column->rows == self->rows, @"Matrix size mismatch");
    double *productarray = self->matrix;
    double *factorarray = column->matrix;
    int cols = self->columns;
    int rws = self->rows;
    for (int i=0; i<rws; i++)
    {
        for (int j=0; j<cols; j++)
        {
            productarray[i*cols + j] /= factorarray[i]; //i!
        }
    }
}

- (Matrix *)appendRow:(Matrix *)row
{
    NSAssert(row->rows == 1 && row->columns == self->columns, @"Matrix size mismatch");
    double *newMatrix = malloc(columns * (rows + 1) * sizeof(double));
    memcpy(newMatrix, self->matrix, columns * rows * sizeof(double));
    memcpy(newMatrix + columns*rows, row->matrix, columns * sizeof(double));
    return [Matrix matrixFromArray:newMatrix rows:rows + 1 columns:columns mode:YCMStrong];
}

- (Matrix *)appendColumn:(Matrix *)column
{
    NSAssert(column->columns == 1 && column->rows == self->rows, @"Matrix size mismatch");
    double *newMatrix = malloc((columns + 1) * rows * sizeof(double));
    int newCols = columns + 1;
    for (int i=0; i < rows; i++)
    {
        memcpy(newMatrix + newCols * i, self->matrix + columns * i, columns * sizeof(double));
        newMatrix[newCols * i + columns] = column->matrix[i];
    }
    return [Matrix matrixFromArray:newMatrix rows:rows columns:columns + 1 mode:YCMStrong];
}

- (Matrix *)removeRow:(int)rowIndex
{
    
    NSAssert(rowIndex < self->rows, @"Index out of bounds");
    double newRows = rows - 1;
    double *newMatrix = malloc(columns * newRows * sizeof(double));
    for (int i=0; i < newRows; i++) // should count to one-less than rows, so newRows
    {
        int idx = i >= rowIndex ? i+1 : i;
        memcpy(newMatrix + columns * i, self->matrix + columns * idx, columns * sizeof(double));
    }
    return [Matrix matrixFromArray:newMatrix rows:newRows columns:columns];
}

- (Matrix *)removeColumn:(int)columnIndex
{
    NSAssert(columnIndex < self->columns, @"Index out of bounds");
    int newCols = columns - 1;
    double *newMatrix = malloc(newCols * rows * sizeof(double));
    for (int i=0; i < rows; i++)
    {
        memcpy(newMatrix + i*newCols,
               self->matrix + i*self->columns,
               columnIndex * sizeof(double));
        memcpy(newMatrix + columnIndex + i*newCols,
               self->matrix + columnIndex + 1  + i*self->columns,
               (newCols - columnIndex) * sizeof(double));
    }
    return [Matrix matrixFromArray:newMatrix rows:rows columns:newCols];
}

- (Matrix *)appendValueAsRow:(double)value
{
    NSAssert(columns == 1, @"Matrix size mismatch – Input needs to be a vector");
    int newRows = rows + 1;
    double *newArray = malloc(columns * newRows * sizeof(double));
    memcpy(newArray, matrix, columns * rows * sizeof(double));
    newArray[columns * newRows - 1] = value;
    return [Matrix matrixFromArray:newArray rows:newRows columns:columns];
}

- (void)applyMatrix:(Matrix *)other i:(int)i j:(int)j
{
    NSAssert(other.rows + 1 <= self.rows && other.columns + j <= self.columns,
             @"Matrix out of bounds");
    int ma = self.rows;
    int na = self.columns;
    int mo = other.rows;
    int no = other.columns;
    for (int io = 0; io<mo; io++)
    {
        for (int jo = 0; jo<no; jo++)
        {
            self->matrix[(io + i) * na + (jo + j)] = other->matrix[io * no + jo];
        }
    }
}

// Fisher-Yates Inside-out Shuffle
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
            // TODO: Speed this up using memcpy
            ret->matrix[i*colCount + j] = ret->matrix[o*colCount + j];
            ret->matrix[o*colCount + j] = self->matrix[i*colCount + j];
        }
    }
    return ret;
}

// Fisher-Yates Shuffle
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
            // TODO: Speed this up using memcpy
            tmp = self->matrix[i*colCount + j];
            self->matrix[i*colCount + j] = self->matrix[o*colCount + j];
            self->matrix[o*colCount + j] = tmp;
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
        for (int j=0; j<rowCount; j++)
        {
            ret->matrix[j*colCount + i] = ret->matrix[j*colCount + o];
            ret->matrix[j*colCount + o] = self->matrix[j*colCount + i];
        }
    }
    return ret;
}

// Fisher-Yates Shuffle
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
            tmp = self->matrix[j*colCount + i];
            self->matrix[j*colCount + i] = self->matrix[j*colCount + o];
            self->matrix[j*colCount + o] = tmp;
        }
    }
}

- (Matrix *)matrixBySamplingRows:(NSUInteger)sampleCount replacement:(BOOL)replacement
{
    int rowSize = self->rows;
    int colSize = self->columns;
    int colMemory = colSize * sizeof(double);
    Matrix *new = [Matrix matrixOfRows:(int)sampleCount columns:colSize];
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
            if (N * (double)arc4random() / ARC4RANDOM_MAX <= n)
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

- (Matrix *)matrixBySamplingColumns:(NSUInteger)sampleCount replacement:(BOOL)replacement
{
    int rowSize = self->rows;
    int colSize = self->columns;
    Matrix *new = [Matrix matrixOfRows:rowSize columns:(int)sampleCount];
    if (replacement)
    {
        for (int i=0; i<sampleCount; i++)
        {
            int rnd = arc4random_uniform((int)self->rows);
            [new setColumn:i value:[self column:rnd]];
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
            if (N * (double)arc4random() / ARC4RANDOM_MAX <= n)
            {
                [new setColumn:samples - n value:[self column:i]];
                n--;
            }
            i++;
            N--;
        }
    }
    return new;
}

@end
