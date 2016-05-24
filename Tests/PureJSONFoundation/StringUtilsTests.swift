//
//  StringUtilsTests.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import XCTest
@testable import PureJSONFoundation

class StringUtilsTests: XCTestCase {
    func testEscapeNewline() {
        XCTAssertEqual(escapeAsJsonString("\n \n"), "\"\\n \\n\"", "for \\n")
    }

    func testEscapeTab() {
        XCTAssertEqual(escapeAsJsonString("\t \t"), "\"\\t \\t\"", "for \\t")
    }

    func testEscapeReturn() {
        XCTAssertEqual(escapeAsJsonString("\r \r"), "\"\\r \\r\"", "for \\r")
    }

    func testEscapeBackslash() {
        XCTAssertEqual(escapeAsJsonString("\\ \\"), "\"\\\\ \\\\\"", "for \\")
    }

    func testEscapeDoublequote() {
        XCTAssertEqual(escapeAsJsonString("\" \""), "\"\\\" \\\"\"", "for \"")
    }

    func testEscapeLineSeparator() {
        XCTAssertEqual(escapeAsJsonString("\" \""), "\"\\\" \\\"\"", "for \"")
    }

}