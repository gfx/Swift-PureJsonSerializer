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
        do {
            let _ = try Json.deserialize("")
            XCTFail("not reached")
        } catch let error as InsufficientTokenError {
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 1, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnexpectedToken() {
        do {
            let _ = try Json.deserialize("?")
            XCTFail("not reached")
        } catch let error as UnexpectedTokenError {
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 1, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSourceLocation() {
        do {
            let _ = try Json.deserialize("[\n   ?")
            XCTFail("not reached")
        } catch let error as UnexpectedTokenError {
            XCTAssertEqual(error.lineNumber, 2, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 5, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExtraTokens() {
        do {
            let _ = try Json.deserialize("[] []")
            XCTFail("not reached")
        } catch let error as ExtraTokenError {
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 4, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInvalidNumber() {
        do {
            let _ = try Json.deserialize("[ 10. ]")
            XCTFail("not reached")
        } catch let error as InvalidNumberError {
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 6, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }


    func testMissingDoubleQuote() {
        do {
            let _ = try Json.deserialize("[ \"foo, null ]")
            XCTFail("not reached")
        } catch let error as InvalidStringError {
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 14, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMissingEscapedChar() {
        do {
            let _ = try Json.deserialize("[ \"foo \\")
            XCTFail("not reached")
        } catch let error as InvalidStringError {
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 8, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMissingColon() {
        do {
            let _ = try Json.deserialize("{ \"foo\" ")
            XCTFail("not reached")
        } catch let error as UnexpectedTokenError {
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 8, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMissingObjecValue() {
        do {
            let _ = try Json.deserialize("{ \"foo\": ")
            XCTFail("not reached")
        } catch let error as InsufficientTokenError {
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 9, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }


    func testInvalidEscapeSequence() {
        do {
            let _ = try Json.deserialize("\"\\uFFF\"")
            XCTFail("not reached")
        } catch let error as InvalidStringError {
            XCTAssertEqual(error.lineNumber, 1, "lineNumbeer")
            XCTAssertEqual(error.columnNumber, 6, "columnNumbeer")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}