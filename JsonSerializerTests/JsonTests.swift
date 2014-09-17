//
//  JsonTests.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import XCTest

class JsonTests: XCTestCase {

    func testConvenienceConvertions() {
        let x = JsonParser.parse("[\"foo bar\", true, false]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[\"foo bar\",true,false]")

            XCTAssertEqual(json[0].stringValue, "foo bar")
            XCTAssertEqual(json[1].boolValue, true)
            XCTAssertEqual(json[2].boolValue, false)

            XCTAssertEqual(json[3].stringValue, "", "out of range")
            XCTAssertEqual(json[3][0].stringValue, "", "no such item")
            XCTAssertEqual(json["no such property"].stringValue, "", "no such property")
            XCTAssertEqual(json["no"]["such"]["property"].stringValue, "", "no such properties")
        case .Error(let error):
            XCTFail(error.description)
        }
    }


    func testConvertFromNilLiteral() {
        let value: Json = nil
        XCTAssertEqual(value, Json.NullValue)
    }

    func testConvertFromBooleanLiteral() {
        let a: Json = true
        XCTAssertEqual(a, Json.from(true))

        let b: Json = false
        XCTAssertEqual(b, Json.from(false))
    }

    func testConvertFromIntegerLiteral() {
        let a: Json = 42
        XCTAssertEqual(a, Json.from(42))
    }

    func testConvertFromFloatLiteral() {
        let a: Json = 3.14
        XCTAssertEqual(a, Json.from(3.14))
    }

    func testConvertFromStringLiteral() {
        let a: Json = "foo"
        XCTAssertEqual(a, Json.from("foo"))
    }

    func testConvertFromArrayLiteral() {
        let a: Json = [nil, true, 10, "foo"]

        switch JsonParser.parse("[null, true, 10, \"foo\"]") {
        case .Success(let expected):
            XCTAssertEqual(a, expected)
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testConvertFromDictionaryLiteral() {
        let a: Json = ["foo": 10, "bar": true]

        switch JsonParser.parse("{ \"foo\": 10, \"bar\": true }") {
        case .Success(let expected):
            XCTAssertEqual(a, expected)
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testPrintable() {
        let x: Printable = Json.from(true)

        XCTAssertEqual(x.description, "true", "Printable#description")
    }

    func testDebugPrintable() {
        let x: DebugPrintable = Json.from(true)

        XCTAssertEqual(x.debugDescription, "true", "DebugPrintable#debugDescription")
    }


    let e: Json = nil
    let b0: Json = false
    let b1: Json = true
    let n0: Json = 0
    let n1: Json = 10
    let s0: Json = ""
    let s1: Json = "foo"
    let a0: Json = []
    let a1: Json = [true, "foo"]
    let o0: Json = [:]
    let o1: Json = ["foo": [10, false]]


    func testNullValueEquality() {
        XCTAssertEqual(e, e)
        XCTAssertNotEqual(e, b0)
        XCTAssertNotEqual(e, n0)
        XCTAssertNotEqual(e, s0)
        XCTAssertNotEqual(e, a0)
        XCTAssertNotEqual(e, o0)
    }

    func testBooleanValueEquality() {
        XCTAssertEqual(b0, b0)
        XCTAssertEqual(b1, b1)
        XCTAssertNotEqual(b0, e)
        XCTAssertNotEqual(b0, b1)
        XCTAssertNotEqual(b0, n0)
        XCTAssertNotEqual(b0, s0)
        XCTAssertNotEqual(b0, a0)
        XCTAssertNotEqual(b0, o0)
    }

    func testNumberValueEquality() {
        XCTAssertEqual(n0, n0)
        XCTAssertEqual(n1, n1)
        XCTAssertNotEqual(n0, e)
        XCTAssertNotEqual(n0, b0)
        XCTAssertNotEqual(n0, n1)
        XCTAssertNotEqual(n0, s0)
        XCTAssertNotEqual(n0, a0)
        XCTAssertNotEqual(n0, o0)
    }

    func testStringValueEquality() {
        XCTAssertEqual(s0, s0)
        XCTAssertEqual(s1, s1)
        XCTAssertNotEqual(s0, e)
        XCTAssertNotEqual(s0, b0)
        XCTAssertNotEqual(s0, n0)
        XCTAssertNotEqual(s0, s1)
        XCTAssertNotEqual(s0, a0)
        XCTAssertNotEqual(s0, o0)
    }

    func testArrayValueEquality() {
        XCTAssertEqual(a0, a0)
        XCTAssertEqual(a1, a1)
        XCTAssertNotEqual(a0, e)
        XCTAssertNotEqual(a0, b0)
        XCTAssertNotEqual(a0, n0)
        XCTAssertNotEqual(a0, s0)
        XCTAssertNotEqual(a0, a1)
        XCTAssertNotEqual(a0, o0)
    }

    func testObjectValueEquality() {
        XCTAssertEqual(o0, o0)
        XCTAssertEqual(o1, o1)
        XCTAssertNotEqual(o0, e)
        XCTAssertNotEqual(o0, b0)
        XCTAssertNotEqual(o0, n0)
        XCTAssertNotEqual(o0, s0)
        XCTAssertNotEqual(o0, a0)
        XCTAssertNotEqual(s0, o1)
    }
}
