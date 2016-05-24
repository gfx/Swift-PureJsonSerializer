//
//  JsonParserTests.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/08.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import XCTest
import Foundation
@testable import PureJSONFoundation

class JsonDeserializerTests: XCTestCase {

    let workDir: String = {
        let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
        let path = "/\(parent)/"
        return path
    }()

    func testEmptyArray() {
        let json = try! JSON.deserialize("[]")
        XCTAssertEqual(json.description, "[]")
    }

    func testEmptyArrayWithSpaces() {
        let json = try! JSON.deserialize(" [ ] ")
        XCTAssertEqual(json.description, "[]")
    }

    func testArray() {
        let json = try! JSON.deserialize("[true,false,null]")
        XCTAssertEqual(json.description, "[true,false,null]")
    }

    func testArrayWithSpaces() {
        let json = try! JSON.deserialize("[ true ,     false , null ]")
        XCTAssertEqual(json.description, "[true,false,null]")
    }

    func testEmptyObject() {
        let json = try! JSON.deserialize("{}")
        XCTAssertEqual(json.description, "{}")
    }

    func testEmptyObjectWithSpace() {
        let json = try! JSON.deserialize(" { } ")
        XCTAssertEqual(json.description, "{}")
    }

    func testObject() {
        let json = try! JSON.deserialize("{\"foo\":[\"bar\",\"baz\"]}")
        XCTAssertEqual(json.description, "{\"foo\":[\"bar\",\"baz\"]}")
    }

    func testObjectWithWhiteSpaces() {
        let json = try! JSON.deserialize(" { \"foo\" : [ \"bar\" , \"baz\" ] } ")
        XCTAssertEqual(json.description, "{\"foo\":[\"bar\",\"baz\"]}")
    }


    func testString() {
        let json = try! JSON.deserialize("[\"foo [\\t] [\\r] [\\n]] [\\\\] bar\"]")
        XCTAssertEqual(json.description, "[\"foo [\\t] [\\r] [\\n]] [\\\\] bar\"]")
    }

    func testStringWithMyltiBytes() {
        let json = try! JSON.deserialize("[\"こんにちは\"]")
        XCTAssertEqual(json[0]!.string, "こんにちは")
        XCTAssertEqual(json.description, "[\"こんにちは\"]")
    }

    func testStringWithMyltiUnicodeScalars() {
        let json = try! JSON.deserialize("[\"江戸前🍣\"]")
        XCTAssertEqual(json[0]!.string!, "江戸前🍣")
        XCTAssertEqual(json[0]!.description, "\"江戸前🍣\"")
        XCTAssertEqual(json.description, "[\"江戸前🍣\"]")
    }

    func testNumberOfInt() {
        let json = try! JSON.deserialize("[0, 10, 234]")
        XCTAssertEqual(json.description, "[0,10,234]")
    }

    func testNumberOfFloat() {
        let json = try! JSON.deserialize("[3.14, 0.035]")
        XCTAssertEqual(json.description, "[3.14,0.035]")
    }

    func testNumberOfExponent() {
        let json = try! JSON.deserialize("[1e2, 1e-2, 3.14e+01]")
        XCTAssertEqual(json[0]!.int, 100)
        XCTAssertEqual(json[1]!.double, 0.01)
        XCTAssertEqual("\(json[2]!.double!)", "31.4")
    }

    func testUnicodeEscapeSequences() {
        let json = try! JSON.deserialize("[\"\\u003c \\u003e\"]")
        XCTAssertEqual(json[0]!.string!, "< >")
    }

    func testUnicodeEscapeSequencesWith32bitsUnicodeScalar() {
        let json = try! JSON.deserialize("[\"\\u0001\\uF363\"]")
        XCTAssertEqual(json[0]!.string, "\u{0001F363}")
    }
    
    func testUnicodeEscapeSequencesWithTwo16bitsUnicodeScalar() {
        let json = try! JSON.deserialize("[\"\\u00015\\uF363\"]")
        XCTAssertEqual(json[0]!.string, "\u{0001}5\u{F363}")
    }

    func testTwitterJson() {
        let json = try! JSON.deserialize(complexJsonExample("tweets"))
        XCTAssertEqual(json["statuses"]![0]!["id_str"]!.string, "250075927172759552")
    }

    func testStackexchangeJson() {
        let json = try! JSON.deserialize(complexJsonExample("stackoverflow-items"))
        XCTAssertEqual(json["items"]![0]!["view_count"]!.int, 18711)
    }

    func testPerformanceExampleWithNSData() {
        let jsonSource = complexJsonExample("tweets")
            self.measure {
            let _ = try! JSON.deserialize(jsonSource)
        }
    }

    func testPerformanceExampleWithString() {
        let jsonSource = String(data: complexJsonExample("tweets"), encoding: NSUTF8StringEncoding)!

        self.measure {
            let _ = try! JSON.deserialize(jsonSource)
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
        let file = workDir + "\(name).json"
print(file)
        return NSData(contentsOfFile: workDir + "\(name).json")!
//        return data?.byteArray ?? []
//        let bundle = NSBundle(for: self.dynamicType)
//        let path = bundle.pathForResource(name, ofType: "json")!
//        return NSData(contentsOfFile: path)!
    }
}
