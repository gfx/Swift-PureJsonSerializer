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
        do {
            let json = try Json.deserialize("[\"foo bar\", true, false]")
            XCTAssertEqual(json.description, "[\"foo bar\",true,false]")
            
            XCTAssertEqual(json[0]!.string!, "foo bar")
            XCTAssertEqual(json[1]!.bool!, true)
            XCTAssertEqual(json[2]!.bool!, false)
            
            XCTAssertEqual(json[3]?.string, nil, "out of range")
            XCTAssertEqual(json[3]?[0]?.string, nil, "no such item")
            XCTAssertEqual(json["no such property"]?.string, nil, "no such property")
            XCTAssertEqual(json["no"]?["such"]?["property"]?.string, nil, "no such properties")
        } catch {
            XCTFail("\(error)")
        }
    }


    func testConvertFromNilLiteral() {
        let value: Json = nil
        XCTAssertEqual(value, Json.null)
    }

    func testConvertFromBooleanLiteral() {
        let a: Json = true
        XCTAssertEqual(a, Json(true))

        let b: Json = false
        XCTAssertEqual(b, Json(false))
    }

    func testConvertFromIntegerLiteral() {
        let a: Json = 42
        XCTAssertEqual(a, Json(42))
    }

    func testConvertFromFloatLiteral() {
        let a: Json = 3.14
        XCTAssertEqual(a, Json(3.14))
    }

    func testConvertFromStringLiteral() {
        let a: Json = "foo"
        XCTAssertEqual(a, Json("foo"))
    }

    func testConvertFromArrayLiteral() {
        let a: Json = [nil, true, 10, "foo"]

        let expected = try! Json.deserialize("[null, true, 10, \"foo\"]")
        XCTAssertEqual(a, expected)
    }

    func testConvertFromDictionaryLiteral() {
        let array: Json = ["foo": 10, "bar": true]

        let expected = try! Json.deserialize("{ \"foo\": 10, \"bar\": true }")
        XCTAssertEqual(array, expected)
    }

    func testPrintable() {
        let x: CustomStringConvertible = Json(true)

        XCTAssertEqual(x.description, "true", "Printable#description")
    }

    func testDebugPrintable() {
        let x: CustomDebugStringConvertible = Json(true)

        XCTAssertEqual(x.debugDescription, "true", "DebugPrintable#debugDescription")
    }

    func testPrlettySerializer() {
        let x = Json([true, [ "foo": 1, "bar": 2 ], false])
        XCTAssertEqual(x.debugDescription,
            "[\n" +
                "  true,\n" +
                "  {\n" +
                "    \"bar\": 2,\n" +
                "    \"foo\": 1 },\n" +
            "  false ]",
            "PrettyJsonSerializer")
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

    func testboolEquality() {
        XCTAssertEqual(b0, b0)
        XCTAssertEqual(b1, b1)
        XCTAssertNotEqual(b0, e)
        XCTAssertNotEqual(b0, b1)
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

    func teststringEquality() {
        XCTAssertEqual(s0, s0)
        XCTAssertEqual(s1, s1)
        XCTAssertNotEqual(s0, e)
        XCTAssertNotEqual(s0, b0)
        XCTAssertNotEqual(s0, n0)
        XCTAssertNotEqual(s0, s1)
        XCTAssertNotEqual(s0, a0)
        XCTAssertNotEqual(s0, o0)
    }

    func testarrayEquality() {
        XCTAssertEqual(a0, a0)
        XCTAssertEqual(a1, a1)
        XCTAssertNotEqual(a0, e)
        XCTAssertNotEqual(a0, b0)
        XCTAssertNotEqual(a0, n0)
        XCTAssertNotEqual(a0, s0)
        XCTAssertNotEqual(a0, a1)
        XCTAssertNotEqual(a0, o0)
    }

    func testobjectEquality() {
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
