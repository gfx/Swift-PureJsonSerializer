//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/11.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//  License: The MIT License
//

import Darwin
import Foundation

public class ParseError {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

public class UnexpectedTokenError: ParseError { }

public class InsufficientTokenError: ParseError { }

public class ExtraTokenError: ParseError { }

public class NonStringKeyError: ParseError {}



let unescapeMapping: [UnicodeScalar: UnicodeScalar] = [
    "t": "\t",
    "r": "\r",
    "n": "\n",
]

let escapeMapping: [Character: Character] = [
    "\t": "t",
    "\r": "r",
    "\n": "n",
    "\\": "\\",
]

public enum Json: Printable {
    case NullValue
    case NumberValue(Double)
    case StringValue(String)
    case BooleanValue(Bool)
    case ArrayValue([Json])
    case ObjectValue([String:Json])

    public var boolValue: Bool {
        get {
            switch self {
            case .NullValue:
                return false
            case .BooleanValue(let b):
                return b
            default:
                return true
            }
        }
    }

    public var doubleValue: Double {
        get {
            switch self {
            case .NumberValue(let n):
                return n
            case .StringValue(let s):
                return atof(s)
            case .BooleanValue(let b):
                return b ? 1.0 : 0.0
            default:
                return 0.0
            }
        }
    }

    public var intValue: Int {
        get { return Int(doubleValue) }
    }

    public var uintValue: UInt {
        get { return UInt(doubleValue) }
    }

    public var stringValue: String {
        get {
            switch self {
            case .NullValue:
                return ""
            case .StringValue(let s):
                return s
            default:
                return description
            }
        }
    }

    public subscript(index: Int) -> Json {
        get {
            switch self {
            case .ArrayValue(let a):
                return index < a.count ? a[index] : .NullValue
            default:
                return .NullValue
            }
        }
    }

    public subscript(key: String) -> Json {
        get {
            switch self {
            case .ObjectValue(let o):
                return o[key] ?? .NullValue
            default:
                return .NullValue
            }
        }
    }

    public var description: String {
        get {
            switch self {
            case .NullValue:
                return "null"
            case .BooleanValue(let b):
                return b ? "true" : "false"
            case .NumberValue(let n):
                // FIXME: truncate fraction pars if possible
                return stringify(n)
            case .StringValue(let s):
                // FIXME: escape meta characters
                return escape(s)
            case .ArrayValue(let a):
                return stringify(a)
            case .ObjectValue(let o):
                return stringify(o)
            }
        }
    }

    func escape(source : String) -> String {
        var s = "\""

        for c in source {
            switch c {
            case "\\", "\r", "\n", "\t":
                s += "\\" + escapeMapping[c]!
                break
            default:
                s.append(c)
                break
            }
        }

        return s + "\""
    }

    func stringify(n: Double) -> String {
        if n == Double(Int32(n)) {
            return Int32(n).description
        } else {
            return n.description
        }
    }

    func stringify(a: [Json]) -> String {
        var s = "["
        for var i = 0; i < a.count; i++ {
            s += a[i].description
            if i != (a.count - 1) {
                s += ","
            }
        }
        return s + "]"
    }

    func stringify(o: [String: Json]) -> String {
        var s = "{"
        var i = 0
        for entry in o {
            s += "\(escape(entry.0)):\(entry.1.description)"
            if i++ != (o.count - 1) {
                s += ","
            }
        }

        return s + "}"
    }
}

func c2byte(s: StaticString) -> Byte {
    return s.start.memory
}

func byte2c(b: Byte) -> UnicodeScalar {
    return UnicodeScalar(b)
}


public class JsonParser {

    public class func parse(source: NSData) -> Result {
        let begin = unsafeBitCast(source.bytes, UnsafePointer<Byte>.self)
        let end = begin.advancedBy(source.length)
        return JsonParser(source, begin, end).parse()
    }

    public class func parse(source: StaticString) -> Result {
        let begin = source.start
        let end = begin.advancedBy(Int(source.byteSize))
        return JsonParser(source.stringValue, begin, end).parse()
    }

    func f(p: UnsafePointer<CChar>) -> UnsafePointer<CChar> {
        return p
    }

    public class func parse(begin: UnsafePointer<Byte>, end: UnsafePointer<Byte>) -> Result {
        return JsonParser(nil, begin, end).parse()
    }

    typealias Iterator = UnsafePointer<Byte>


    let originalSource: AnyObject?
    let beg: Iterator
    let end: Iterator
    var cur: Iterator

    var lineNumber = 1
    var columnNumber = 1

    public init(_ source: AnyObject?, _ begin: UnsafePointer<Byte>, _ end: UnsafePointer<Byte>) {
        self.originalSource = source
        self.beg = begin
        self.end = end
        self.cur = begin
    }

    public enum Result {
        case Success(json: Json, parser: JsonParser)
        case Error(error: ParseError, parser: JsonParser)
    }

    func parse() -> Result {
        skipWhitespaces()

        if cur == end {
            return error(InsufficientTokenError("empty string"))
        }

        switch byte2c(cur.memory) {
        case "n":
            return parseSymbol("null", Json.NullValue)
        case "t":
            return parseSymbol("true", Json.BooleanValue(true))
        case "f":
            return parseSymbol("false", Json.BooleanValue(false))
        case "-", "0" ... "9":
            return parseNumber()
        case "\"":
            return parseString()
        case "{":
            return parseObject()
        case "[":
            return parseArray()
        case (let c):
            return error(UnexpectedTokenError("unexpected token: \(c)"))
        }
    }

    var currentSymbol: Character {
        get { return Character(byte2c(cur.memory)) }
    }

    func parseSymbol(target: StaticString, _ iftrue: @autoclosure () -> Json) -> Result {
        if expect(target) {
            return Result.Success(json: iftrue(), parser: self)
        } else {
            return error(UnexpectedTokenError("expected \"\(target)\" but \(currentSymbol)"))
        }
    }

    func parseString() -> Result {
        assert(byte2c(cur.memory) == "\"", "points a double quote")
        cur++

        var s = ""
        LOOP: for ; cur != end; cur++ {
            let c = byte2c(cur.memory)
            switch c {
            case "\\":
                cur++
                s.append(parseEscapedChar(byte2c(cur.memory)))
                break
            case "\"": // end of the string literal
                cur++
                break LOOP
            default:
                s.append(c)
            }
        }

        return Result.Success(json: .StringValue(s), parser: self)
    }

    func parseEscapedChar(c: UnicodeScalar) -> UnicodeScalar {
        // TODO: unicode escape sequence
        return unescapeMapping[c] ?? c
    }

    func parseNumber() -> Result {
        let sign = expect("-") ? -1.0 : 1.0

        let start = index
        var n = Double()

        // integer
        LOOP: for ; cur != end; cur++ {
            let c = byte2c(cur.memory)

            switch c {
            case "0" ... "9":
                let d = String(c).toInt()!
                n = (n * 10.0) + Double(d)
            default:
                break LOOP
            }
        }

        // fraction
        if expect(".") {
            var factor = 0.1

            LOOP: for ; cur != end; cur++ {
                let c = byte2c(cur.memory)
                switch c {
                case "0" ... "9":
                    let d = String(c).toInt()!
                    n += (Double(d) * factor)
                    factor /= 10
                default:
                    break LOOP
                }
            }
        }

        return Result.Success(json: .NumberValue(sign * n), parser: self)
    }

    func parseObject() -> Result {
        assert(byte2c(cur.memory) == "{", "points \"{\"")
        cur++

        var o = [String:Json]()

        LOOP: for ;cur != end && !expect("}"); cur++ {
            // key
            switch parse() {
            case .Success(let keyValue, _):
                switch keyValue {
                case .StringValue(let key):
                    if !expect(":") {
                        return error(UnexpectedTokenError("missing colon (:)"))
                    }

                    // value
                    switch parse() {
                    case .Success(let value, _):
                        o[key] = value
                        break
                    case (let error):
                        return error
                    }

                    skipWhitespaces()
                    if expect(",") {
                        break
                    } else if expect("}") {
                        break LOOP
                    } else {
                        return error(UnexpectedTokenError("missing comma (,)"))
                    }
                default:
                    return error(NonStringKeyError("unexpected value for object key"))
                }
            case (let error):
                return error
            }
        }

        return Result.Success(json: .ObjectValue(o), parser: self)
    }

    func parseArray() -> Result {
        assert(byte2c(cur.memory) == "[", "points \"[\"")
        cur++

        var a = Array<Json>()

        LOOP: for ;cur != end && !expect("]"); cur++ {
            switch parse() {
            case .Success(let json, _):
                a.append(json)

                if expect(",") {
                    break
                } else if expect("]") {
                    break LOOP
                } else {
                    return error(UnexpectedTokenError("missing comma (,) (token: \(currentSymbol))"))
                }
            case (let error):
                return error
            }

        }

        return Result.Success(json: .ArrayValue(a), parser: self)
    }


    func expect(target: StaticString) -> Bool {
        skipWhitespaces()

        if !isIdentifier(target.start.memory) {
            // when single character
            if target.start.memory == cur.memory {
                cur++
                return true
            } else {
                return false
            }
        }

        let start = cur

        var p = target.start
        let endp = p.advancedBy(Int(target.byteSize))

        LOOP: for ; p != endp; p++, cur++ {
            if !isIdentifier(cur.memory) {
                break
            }

            if p.memory != cur.memory {
                cur = start // unread
                return false
            }
        }

        return true
    }

    // only "true", "false", "null" are identifiers
    func isIdentifier(c: Byte) -> Bool {
        switch byte2c(c) {
        case "a" ... "z":
            return true
        default:
            return false
        }
    }

    func skipWhitespaces() {
        LOOP: for ; cur != end; cur++ {
            switch byte2c(cur.memory) {
            case " ", "\t", "\r", "\n":
                break
            default:
                return
            }
        }
    }

    func error(error: ParseError) -> Result {
        return .Error(error: error, parser: self)
    }
}
