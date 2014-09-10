//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/11.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//  License: The MIT License
//

import Darwin

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



let unescapeMapping: [Character: Character] = [
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
    case ObjectValue(Dictionary<String, Json>)

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

public class JsonParser: SequenceType {
    public class func parse(source: String) -> Result {
        return JsonParser(source).parse()
    }

    let source: String
    var index: String.Index

    var lineNumber = 1
    var columnNumber = 1

    public init(_ source: String, _ index: String.Index) {
        self.source = source
        self.index = index
    }

    public convenience init(_ source: String) {
        self.init(source, source.startIndex)
    }

    public enum Result {
        case Success(json: Json, parser: JsonParser)
        case Error(error: ParseError, parser: JsonParser)
    }

    func parse() -> Result {
        skipWhitespaces()

        if index == source.endIndex {
            return error(InsufficientTokenError("empty string"))
        }

        switch source[index] {
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

    func parseSymbol(target: String, _ iftrue: @autoclosure () -> Json) -> Result {
        if expect(target) {
            return Result.Success(json: iftrue(), parser: self)
        } else {
            return error(UnexpectedTokenError("expected \"\(target)\" but \(source[index])"))
        }
    }

    func parseString() -> Result {
        assert(source[index] == "\"", "points a double quote")
        index++

        var s = ""
        LOOP: for c in self {
            switch c {
            case "\\":
                s.append(parseEscapedChar(source[index++]))
                break
            case "\"":
                break LOOP
            default:
                s.append(c)
            }
        }

        return Result.Success(json: .StringValue(s), parser: self)
    }

    func parseEscapedChar(c: Character) -> Character {
        // TODO: unicode escape sequence
        return unescapeMapping[c] ?? c
    }

    func parseNumber() -> Result {
        let sign = expect("-") ? -1.0 : 1.0

        let start = index
        var n = Double()

        // integer
        LOOP: for c in self {
            switch c {
            case "0" ... "9":
                let d = String(c).toInt()!
                n = (n * 10.0) + Double(d)
            default:
                index--
                break LOOP
            }
        }

        // fraction
        if expect(".") {
            var factor = 0.1

            LOOP: for c in self {
                switch c {
                case "0" ... "9":
                    let d = String(c).toInt()!
                    n += (Double(d) * factor)
                    factor /= 10
                default:
                    index--
                    break LOOP
                }
            }
        }

        return Result.Success(json: .NumberValue(sign * n), parser: self)
    }

    func parseObject() -> Result {
        assert(source[index] == "{", "points \"{\"")
        index++

        var o = Dictionary<String, Json>()

        LOOP: while index != source.endIndex && !expect("}") {
            // key
            switch parse() {
            case .Success(let keyValue, _):
                var key : String
                switch keyValue {
                case .StringValue(let _key):
                    key = _key
                    break
                default:
                    return error(NonStringKeyError("unexpected value for object key"))
                }

                skipWhitespaces()
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
            case (let error):
                return error
            }
        }

        return Result.Success(json: .ObjectValue(o), parser: self)
    }

    func parseArray() -> Result {
        assert(source[index] == "[", "points \"[\"")
        index++

        var a = Array<Json>()

        LOOP: while index != source.endIndex && !expect("]") {
            switch parse() {
            case .Success(let json, _):
                a.append(json)

                skipWhitespaces()
                if expect(",") {
                    break
                } else if expect("]") {
                    break LOOP
                } else {
                    return error(UnexpectedTokenError("missing comma (,)"))
                }
            case (let error):
                return error
            }

        }

        return Result.Success(json: .ArrayValue(a), parser: self)
    }


    func expect(target: String) -> Bool {
        skipWhitespaces()

        let start = index
        if token() == target {
            return true
        } else {
            index = start
            return false
        }
    }

    func token() -> String {
        let start = index

        if !isIdentifier(source[index]) {
            return String(source[index++])
        }

        for c in self {
            if !isIdentifier(c) {
                index--
                break
            }
        }
        return source[start ..< index]
    }

    // only "true", "false", "null" are identifiers
    func isIdentifier(c: Character) -> Bool {
        switch c {
        case "a" ... "z":
            return true
        default:
            return false
        }
    }

    func skipWhitespaces() {
        for c in self {
            switch c {
            case " ", "\t", "\r", "\n":
                break
            default:
                index--
                return
            }
        }
    }

    func error(error: ParseError) -> Result {
        return .Error(error: error, parser: self)
    }

    public func generate() -> GeneratorOf<Character> {
        return GeneratorOf<Character> {
            if self.index != self.source.endIndex {
                let c = self.source[self.index++]
                
                if c == "\n" {
                    self.lineNumber++
                    self.columnNumber = 1
                } else {
                    self.columnNumber++
                }
                
                return c
            } else {
                return .None
            }
        }
    }
}
