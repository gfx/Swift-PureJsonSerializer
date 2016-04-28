//
//  JsonParserTests.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/08.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import XCTest
import Foundation

class JsonDeserializerTests: XCTestCase {

    func testEmptyArray() {
        let json = try! Json.deserialize("[]")
        XCTAssertEqual(json.description, "[]")
    }

    func testEmptyArrayWithSpaces() {
        let json = try! Json.deserialize(" [ ] ")
        XCTAssertEqual(json.description, "[]")
    }

    func testArray() {
        let json = try! Json.deserialize("[true,false,null]")
        XCTAssertEqual(json.description, "[true,false,null]")
    }

    func testArrayWithSpaces() {
        let json = try! Json.deserialize("[ true ,     false , null ]")
        XCTAssertEqual(json.description, "[true,false,null]")
    }

    func testEmptyObject() {
        let json = try! Json.deserialize("{}")
        XCTAssertEqual(json.description, "{}")
    }

    func testEmptyObjectWithSpace() {
        let json = try! Json.deserialize(" { } ")
        XCTAssertEqual(json.description, "{}")
    }

    func testObject() {
        let json = try! Json.deserialize("{\"foo\":[\"bar\",\"baz\"]}")
        XCTAssertEqual(json.description, "{\"foo\":[\"bar\",\"baz\"]}")
    }

    func testObjectWithWhiteSpaces() {
        let json = try! Json.deserialize(" { \"foo\" : [ \"bar\" , \"baz\" ] } ")
        XCTAssertEqual(json.description, "{\"foo\":[\"bar\",\"baz\"]}")
    }


    func testString() {
        let json = try! Json.deserialize("[\"foo [\\t] [\\r] [\\n]] [\\\\] bar\"]")
        XCTAssertEqual(json.description, "[\"foo [\\t] [\\r] [\\n]] [\\\\] bar\"]")
    }

    func testStringWithMyltiBytes() {
        let json = try! Json.deserialize("[\"こんにちは\"]")
        XCTAssertEqual(json[0]!.stringValue, "こんにちは")
        XCTAssertEqual(json.description, "[\"こんにちは\"]")
    }

    func testStringWithMyltiUnicodeScalars() {
        let json = try! Json.deserialize("[\"江戸前🍣\"]")
        XCTAssertEqual(json[0]!.stringValue!, "江戸前🍣")
        XCTAssertEqual(json[0]!.description, "\"江戸前🍣\"")
        XCTAssertEqual(json.description, "[\"江戸前🍣\"]")
    }

    func testNumberOfInt() {
        let json = try! Json.deserialize("[0, 10, 234]")
        XCTAssertEqual(json.description, "[0,10,234]")
    }

    func testNumberOfFloat() {
        let json = try! Json.deserialize("[3.14, 0.035]")
        XCTAssertEqual(json.description, "[3.14,0.035]")
    }

    func testNumberOfExponent() {
        let json = try! Json.deserialize("[1e2, 1e-2, 3.14e+01]")
        XCTAssertEqual(json[0]!.intValue, 100)
        XCTAssertEqual(json[1]!.doubleValue, 0.01)
        XCTAssertEqual("\(json[2]!.doubleValue!)", "31.4")
    }

    func testUnicodeEscapeSequences() {
        let json = try! Json.deserialize("[\"\\u003c \\u003e\"]")
        XCTAssertEqual(json[0]!.stringValue!, "< >")
    }

    func testUnicodeEscapeSequencesWith32bitsUnicodeScalar() {
        let json = try! Json.deserialize("[\"\\u0001\\uF363\"]")
        XCTAssertEqual(json[0]!.stringValue, "\u{0001F363}")
    }
    
    func testUnicodeEscapeSequencesWithTwo16bitsUnicodeScalar() {
        let json = try! Json.deserialize("[\"\\u00015\\uF363\"]")
        XCTAssertEqual(json[0]!.stringValue, "\u{0001}5\u{F363}")
    }

    func testTwitterJson() {
        let json = try! Json.deserialize(complexJsonExample("tweets"))
        XCTAssertEqual(json["statuses"]![0]!["id_str"]!.stringValue, "250075927172759552")
    }

    func testStackexchangeJson() {
        let json = try! Json.deserialize(complexJsonExample("stackoverflow-items"))
        XCTAssertEqual(json["items"]![0]!["view_count"]!.intValue, 18711)
    }

    func testPerformanceExampleWithNSData() {
        let jsonSource = complexJsonExample("tweets")
            self.measure {
            let _ = try! Json.deserialize(jsonSource)
        }
    }

    func testPerformanceExampleWithString() {
        let jsonSource = String(data: complexJsonExample("tweets"), encoding: NSUTF8StringEncoding)!

        self.measure {
            let _ = try! Json.deserialize(jsonSource)
        }
    }

    func testPerformanceExampleInJSONSerialization() {
        let jsonSource = complexJsonExample("tweets")
        self.measure {
            let _: AnyObject? = try! NSJSONSerialization.jsonObject(with: jsonSource,
                                                                    options: .mutableContainers)
        }
    }

    func complexJsonExample(_ name: String) -> NSData {
        let bundle = NSBundle(for: self.dynamicType)
        let path = bundle.pathForResource(name, ofType: "json")!
        return NSData(contentsOfFile: path)!
    }
}
