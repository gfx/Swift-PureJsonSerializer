//
//  StringUtilsTests.swift
//  JSONSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import XCTest
@testable import PureJSONFoundation

class StringUtilsTests: XCTestCase {
    func testEscapeNewline() {
        XCTAssertEqual(escapeAsJSONString("\n \n"), "\"\\n \\n\"", "for \\n")
    }

    func testEscapeTab() {
        XCTAssertEqual(escapeAsJSONString("\t \t"), "\"\\t \\t\"", "for \\t")
    }

    func testEscapeReturn() {
        XCTAssertEqual(escapeAsJSONString("\r \r"), "\"\\r \\r\"", "for \\r")
    }

    func testEscapeBackslash() {
        XCTAssertEqual(escapeAsJSONString("\\ \\"), "\"\\\\ \\\\\"", "for \\")
    }

    func testEscapeDoublequote() {
        XCTAssertEqual(escapeAsJSONString("\" \""), "\"\\\" \\\"\"", "for \"")
    }

    func testEscapeLineSeparator() {
        XCTAssertEqual(escapeAsJSONString("\" \""), "\"\\\" \\\"\"", "for \"")
    }

}