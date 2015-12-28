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
        let x = JsonParser.parse("[]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testEmptyArrayWithSpaces() {
        let x = JsonParser.parse(" [ ] ")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testArray() {
        let x = JsonParser.parse("[true,false,null]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[true,false,null]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testArrayWithSpaces() {
        let x = JsonParser.parse("[ true , false , null ]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[true,false,null]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testEmptyObject() {
        let x = JsonParser.parse("{}")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "{}")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testEmptyObjectWithSpace() {
        let x = JsonParser.parse(" { } ")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "{}")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testObject() {
        let x = JsonParser.parse("{\"foo\":[\"bar\",\"baz\"]}")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "{\"foo\":[\"bar\",\"baz\"]}")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testObjectWithWhiteSpaces() {
        let x = JsonParser.parse(" { \"foo\" : [ \"bar\" , \"baz\" ] } ")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "{\"foo\":[\"bar\",\"baz\"]}")
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
            XCTAssertEqual(json[0].description, "\"江戸前🍣\"")
            XCTAssertEqual(json.description, "[\"江戸前🍣\"]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testNumberOfInt() {
        let x = JsonParser.parse("[0, 10, 234]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[0,10,234]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testNumberOfFloat() {
        let x = JsonParser.parse("[3.14, 0.035]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json.description, "[3.14,0.035]")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testNumberOfExponent() {
        let x = JsonParser.parse("[1e2, 1e-2, 3.14e+01]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json[0].stringValue, "100")
            XCTAssertEqual(json[1].stringValue, "0.01")
            XCTAssertEqual(json[2].stringValue, "31.4")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testUnicodeEscapeSequences() {
        let x = JsonParser.parse("[\"\\u003c \\u003e\"]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json[0].stringValue, "< >")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testUnicodeEscapeSequencesWith32bitsUnicodeScalar() {
        let x = JsonParser.parse("[\"\\u0001F363\"]")

        switch x {
        case .Success(let json):
            XCTAssertEqual(json[0].stringValue, "\u{0001F363}")
        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testTwitterJson() {
        let x = JsonParser.parse(complexJsonExample("tweets"))
        switch x {
        case .Success(let json):
            XCTAssertEqual(json["statuses"][0]["id_str"].stringValue, "250075927172759552")

        case .Error(let error):
            XCTFail(error.description)
        }
    }

    func testStackexchangeJson() {
        let x = JsonParser.parse(complexJsonExample("stackoverflow-items"))
        switch x {
        case .Success(let json):
            XCTAssertEqual(json["items"][0]["view_count"].stringValue, "18711")

        case .Error(let error):
            XCTFail(error.description)
        }
    }


    func testPerformanceExampleWithNSData() {
        let jsonSource = complexJsonExample("tweets")

        self.measureBlock {
            switch JsonParser.parse(jsonSource) {
            case .Success(_):
                break
            case .Error(let error):
                XCTFail(error.description)
            }
        }
    }

    func testPerformanceExampleWithString() {
        let jsonSource = NSString(data: complexJsonExample("tweets"), encoding: NSUTF8StringEncoding) as! String

        self.measureBlock {
            switch JsonParser.parse(jsonSource) {
            case .Success(_):
                break
            case .Error(let error):
                XCTFail(error.description)
            }
        }
    }

    func testPerformanceExampleInJSONSerialization() {
        let jsonSource = complexJsonExample("tweets")
        self.measureBlock {
            let dict: AnyObject? = try! NSJSONSerialization
                .JSONObjectWithData(jsonSource, options: .MutableContainers)
        }
    }

    func complexJsonExample(name: String) -> NSData {
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource(name, ofType: "json")!
        return NSData(contentsOfFile: path)!
    }
}
