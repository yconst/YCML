//
//  YCML_Tests__Swift_.swift
//  YCML Tests (Swift)
//
//  Created by Ioannis Chatzikonstantinou on 10/3/15.
//  Copyright (c) 2015 Yannis Chatzikonstantinou. All rights reserved.
//

import Cocoa
import XCTest
import YCML
import YCMatrix

class YCML_Tests__Swift_: XCTestCase {
    
    func testExample() {
        var trainingData = self.matrixWithCSVName("housing", removeFirst: true)
        trainingData.shuffleColumns()
        var cvData = trainingData.matrixWithColumnsInRange(NSMakeRange(trainingData.columns-20, 19))
        trainingData = trainingData.matrixWithColumnsInRange(NSMakeRange(0, trainingData.columns-20))
        var trainingOutput = trainingData.getRow(13)
        var trainingInput = trainingData.removeRow(13)
        var cvOutput = cvData.getRow(13)
        var cvInput = cvData.removeRow(13)
        var trainer = YCELMTrainer()
        trainer.settings["C"] = 0.5E-9
        
        var model = trainer.train(nil, inputMatrix: trainingInput, outputMatrix: trainingOutput)
        
        var predictedOutput = model.activateWithMatrix(cvInput)
        
        predictedOutput.subtract(cvOutput)
        predictedOutput.elementWiseMultiply(predictedOutput)
        var RMSE = sqrt(1.0 / Double(predictedOutput.columns) * predictedOutput.sum)
        NSLog("%@", RMSE)
        XCTAssertLessThan(RMSE, 9.0, "RMSE above threshold")
    }
    
    func matrixWithCSVName(name: NSString, removeFirst: Bool) -> Matrix
    {
        var output: Matrix?
        let bundle = NSBundle(forClass: self.dynamicType)
        let filePath = bundle.pathForResource("housing", ofType: "csv")
        var fileContents = NSString(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding, error: nil)!
        fileContents = fileContents.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
        var rows = fileContents.componentsSeparatedByString("\n") as Array<NSString>
        if (removeFirst).boolValue{
            rows.removeAtIndex(0)
        }
        var counter: Int32 = 0
        for row in rows
        {
            var fields = row.componentsSeparatedByString(",") as Array<NSNumber>
            if (output == nil)
            {
                var rowCount = Int32(fields.count)
                var columnCount = Int32(rows.count)
                output = Matrix(ofRows: rowCount, columns: columnCount)
            }
            var rowMatrix = Matrix(fromNSArray: fields, rows: Int32(fields.count), columns: 1)
            output!.setColumn(counter, value: rowMatrix)
        }
        return output!
    }
    
}
