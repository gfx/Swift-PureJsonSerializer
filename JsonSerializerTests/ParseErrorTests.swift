//
//  ParseErrorTests.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/11.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import XCTest

class ParseErrorTests: XCTestCase {

    func testEmptyString() {
        let x = JsonParser.parse("")

        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):

            XCTAssert(error is InsufficientTokenError, error.description)
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 1, "columnNumbeer")
        }
    }

    func testUnexpectedToken() {
        let x = JsonParser.parse("?")

        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):
            XCTAssert(error is UnexpectedTokenError, error.description)
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 1, "columnNumbeer")
        }
    }

    func testSourceLocation() {
        let x = JsonParser.parse("[\n   ?")

        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):
            XCTAssert(error is UnexpectedTokenError, error.description)
            XCTAssertEqual(error.lineNumber, 2, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 5, "columnNumbeer")
        }
    }

    func testExtraTokens() {
        let x = JsonParser.parse("[] []")

        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):
            XCTAssert(error is ExtraTokenError, error.description)
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 4, "columnNumbeer")
        }

    }

    func testInvalidNumber() {
        let x = JsonParser.parse("[ 10. ]")
        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):
            XCTAssert(error is InvalidNumberError, error.description)
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 6, "columnNumbeer")
        }
    }


    func testMissingDoubleQuote() {
        let x = JsonParser.parse("[ \"foo, null ]")
        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):
            XCTAssert(error is InvalidStringError, error.description)
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 14, "columnNumbeer")
        }
    }

    func testMissingEscapedChar() {
        let x = JsonParser.parse("[ \"foo \\")
        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):
            XCTAssert(error is InvalidStringError, error.description)
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 8, "columnNumbeer")
        }
    }

    func testMissingColon() {
        let x = JsonParser.parse("{ \"foo\" ")
        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):
            XCTAssert(error is UnexpectedTokenError, error.description)
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 8, "columnNumbeer")
        }
    }

    func testMissingObjecValue() {
        let x = JsonParser.parse("{ \"foo\": ")
        switch x {
        case .Success(_):
            XCTFail("not reached")
        case .Error(let error):
            XCTAssert(error is InsufficientTokenError, error.description)
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 9, "columnNumbeer")
        }
    }


    func testInvalidEscapeSequence() {        return // TODO

        let x = JsonParser.parse("[\"\\uFFFFFFFFFFFFFFFF\"]")

        switch x {
        case .Success(let json):
            XCTFail("not reached: \(json)")
        case .Error(let error):
            XCTAssert(error is InvalidNumberError, error.description)
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 9, "columnNumbeer")
        }
    }
}