//
//  ParseErrorTests.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/11.
//  Copyright (c) 2014年 Fuji Goro. All rights reserved.
//

import XCTest

class ParseErrorTests: XCTestCase {

    func testEmptyString() {
        let x = JsonParser.parse("")

        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):

            XCTAssert(error is InsufficientTokenError, "empty string")
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 1, "columnNumbeer")
        }
    }
}