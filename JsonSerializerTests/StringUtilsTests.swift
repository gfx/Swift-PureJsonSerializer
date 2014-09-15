//
//  StringUtilsTests.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import XCTest

class StringUtilsTests: XCTestCase {
    func testEscapedN() {
        XCTAssertEqual(escapeAsJsonString("\n \n"), "\"\\n \\n\"", "for \\n")
    }

    func testEscapedT() {
        XCTAssertEqual(escapeAsJsonString("\t \t"), "\"\\t \\t\"", "for \\t")
    }

    func testEscapedR() {
        XCTAssertEqual(escapeAsJsonString("\r \r"), "\"\\r \\r\"", "for \\r")
    }

    func testEscapedBackslash() {
        XCTAssertEqual(escapeAsJsonString("\\ \\"), "\"\\\\ \\\\\"", "for \\")
    }

    func testEscapedDoublequote() {
        XCTAssertEqual(escapeAsJsonString("\" \""), "\"\\\" \\\"\"", "for \"")
    }
}