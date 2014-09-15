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
        XCTAssertEqual(escapeAsJsonString("\\ \\"), "\"\\u005c \\u005c\"", "for \\")
    }

    func testEscapedDoublequote() {
        XCTAssertEqual(escapeAsJsonString("\" \""), "\"\\u0022 \\u0022\"", "for \"")
    }

    func testUnsecureCharacters() {
        XCTAssertEqual( escapeAsJsonString("&foo\"bar'<b>baz</b>\\ / </script>=-;+\t\r\nfoo\\"),
            "\"\\u0026foo\\u0022bar\\u0027\\u003cb\\u003ebaz\\u003c/b\\u003e\\u005c / " +
            "\\u003c/script\\u003e\\u003d\\u002d\\u003b\\u002b\\t\\r\\nfoo\\u005c\"")

        XCTAssertEqual( escapeAsJsonString("\u{2028}\u{2029}\u{6771}\u{4eac}\u{7802}\u{6f20}"),
            "\"\\u2028\\u2029\u{6771}\u{4eac}\u{7802}\u{6f20}\"")
    }
}