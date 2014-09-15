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
        let x = JsonParser.parse(" [ ] ")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }


    func testArray() {
        let x = JsonParser.parse("[true, false, true]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[true,false,true]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testEmptyObject() {
        let x = JsonParser.parse(" { } ")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "{}")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testString() {
        let x = JsonParser.parse("[\"foo [\\t] [\\r] [\\n]] [\\\\] bar\"]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[\"foo [\\t] [\\r] [\\n]] [\\\\] bar\"]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testStringWithMyltiBytes() {
        let x = JsonParser.parse("[\"こんにちは\"]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json[0].stringValue, "こんにちは")
            XCTAssertEqual(json.description, "[\"こんにちは\"]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testStringWithMyltiUnicodeScalars() {
        let x = JsonParser.parse("[\"江戸前🍣\"]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json[0].stringValue, "江戸前🍣")
            XCTAssertEqual(json.description, "[\"江戸前🍣\"]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testNumberOfInt() {
        let x = JsonParser.parse("[10]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[10]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testNumberOfFloat() {
        let x = JsonParser.parse("[3.14]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[3.14]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testUnicodeEscapeSequences() {
        return // TODO
        let x = JsonParser.parse("[\"\\u003c \\u003e\"]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json[0].stringValue, "< >")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testComplexJson() {
        let x = JsonParser.parse(complexJsonExample())
        switch x {
        case .Success(let json):
            XCTAssertEqual(json["statuses"][0]["id_str"].stringValue, "250075927172759552")

        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testPerformanceExample() {
        let jsonSource = complexJsonExample()

        self.measureBlock {
            switch JsonParser.parse(jsonSource) {
            case .Success(let json):
                XCTAssertTrue(true)
            case .Error(let error):
                XCTFail(error.description)
            }
        }
    }

    func testPerformanceExampleInJSONSerialization() {
        let jsonSource = complexJsonExample()
        self.measureBlock {
            var error: NSError? = nil
            let dict: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonSource, options: .MutableContainers, error: &error)

            switch error {
            case .None:
                break
            case .Some(let e):
                XCTFail("error: \(e)")
            }
        }
    }

    func complexJsonExample() -> NSData {
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource("tweets", ofType: "json")!
        return NSData(contentsOfFile: path)
    }
}
