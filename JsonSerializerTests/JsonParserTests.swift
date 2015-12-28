//
//  JsonParserTests.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/08.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import XCTest

class JsonParserTests: XCTestCase {

    func testEmptyArray() {
        let json = try! JsonParser.parse("[]")
        XCTAssertEqual(json.description, "[]")
    }

    func testEmptyArrayWithSpaces() {
        let json = try! JsonParser.parse(" [ ] ")
        XCTAssertEqual(json.description, "[]")
    }

    func testArray() {
        let json = try! JsonParser.parse("[true,false,null]")
        XCTAssertEqual(json.description, "[true,false,null]")
    }

    func testArrayWithSpaces() {
        let json = try! JsonParser.parse("[ true , false , null ]")
        XCTAssertEqual(json.description, "[true,false,null]")
    }

    func testEmptyObject() {
        let json = try! JsonParser.parse("{}")
        XCTAssertEqual(json.description, "{}")
    }

    func testEmptyObjectWithSpace() {
        let json = try! JsonParser.parse(" { } ")
        XCTAssertEqual(json.description, "{}")
    }

    func testObject() {
        let json = try! JsonParser.parse("{\"foo\":[\"bar\",\"baz\"]}")
        XCTAssertEqual(json.description, "{\"foo\":[\"bar\",\"baz\"]}")
    }

    func testObjectWithWhiteSpaces() {
        let json = try! JsonParser.parse(" { \"foo\" : [ \"bar\" , \"baz\" ] } ")
        XCTAssertEqual(json.description, "{\"foo\":[\"bar\",\"baz\"]}")
    }


    func testString() {
        let json = try! JsonParser.parse("[\"foo [\\t] [\\r] [\\n]] [\\\\] bar\"]")
        XCTAssertEqual(json.description, "[\"foo [\\t] [\\r] [\\n]] [\\\\] bar\"]")
    }

    func testStringWithMyltiBytes() {
        let json = try! JsonParser.parse("[\"こんにちは\"]")
        XCTAssertEqual(json[0].stringValue, "こんにちは")
        XCTAssertEqual(json.description, "[\"こんにちは\"]")
    }

    func testStringWithMyltiUnicodeScalars() {
        let json = try! JsonParser.parse("[\"江戸前🍣\"]")
        XCTAssertEqual(json[0].stringValue, "江戸前🍣")
        XCTAssertEqual(json[0].description, "\"江戸前🍣\"")
        XCTAssertEqual(json.description, "[\"江戸前🍣\"]")
    }

    func testNumberOfInt() {
        let json = try! JsonParser.parse("[0, 10, 234]")
        XCTAssertEqual(json.description, "[0,10,234]")
    }

    func testNumberOfFloat() {
        let json = try! JsonParser.parse("[3.14, 0.035]")
        XCTAssertEqual(json.description, "[3.14,0.035]")
    }

    func testNumberOfExponent() {
        let json = try! JsonParser.parse("[1e2, 1e-2, 3.14e+01]")
        XCTAssertEqual(json[0].stringValue, "100")
        XCTAssertEqual(json[1].stringValue, "0.01")
        XCTAssertEqual(json[2].stringValue, "31.4")
    }

    func testUnicodeEscapeSequences() {
        let json = try! JsonParser.parse("[\"\\u003c \\u003e\"]")
        XCTAssertEqual(json[0].stringValue, "< >")
    }

    func testUnicodeEscapeSequencesWith32bitsUnicodeScalar() {
        let json = try! JsonParser.parse("[\"\\u0001F363\"]")
        XCTAssertEqual(json[0].stringValue, "\u{0001F363}")
    }

    func testTwitterJson() {
        let json = try! JsonParser.parse(complexJsonExample("tweets"))
        XCTAssertEqual(json["statuses"][0]["id_str"].stringValue, "250075927172759552")
    }

    func testStackexchangeJson() {
        let json = try! JsonParser.parse(complexJsonExample("stackoverflow-items"))
        XCTAssertEqual(json["items"][0]["view_count"].stringValue, "18711")
    }


    func testPerformanceExampleWithNSData() {
        let jsonSource = complexJsonExample("tweets")

        self.measureBlock {
            let _ = try! JsonParser.parse(jsonSource)
        }
    }

    func testPerformanceExampleWithString() {
        let jsonSource = NSString(data: complexJsonExample("tweets"), encoding: NSUTF8StringEncoding) as! String

        self.measureBlock {
            let _ = try! JsonParser.parse(jsonSource)
        }
    }

    func testPerformanceExampleInJSONSerialization() {
        let jsonSource = complexJsonExample("tweets")
        self.measureBlock {
            let _: AnyObject? = try! NSJSONSerialization
                .JSONObjectWithData(jsonSource, options: .MutableContainers)
        }
    }

    func complexJsonExample(name: String) -> NSData {
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource(name, ofType: "json")!
        return NSData(contentsOfFile: path)!
    }
}
