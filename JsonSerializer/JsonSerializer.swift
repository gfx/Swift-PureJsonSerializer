//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/11.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//  License: The MIT License
//

// MARK: pure Swift

protocol Parser {
    var lineNumber: Int { get }
    var columnNumber: Int { get }
}

public class ParseError: Printable {
    public let reason: String
    let parser: Parser

    public var lineNumber: Int {
        get { return parser.lineNumber }
    }
    public var columnNumber: Int {
        get { return parser.columnNumber }
    }

    public var description: String {
        get {
            return "\(reflect(self).summary)[\(lineNumber):\(columnNumber)]: \(reason)"
        }
    }

    init(_ reason: String, _ parser: Parser) {
        self.reason = reason
        self.parser = parser
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

private func byte2cchar(b: Byte) -> CChar {
    if b < 0x80 {
        return CChar(b)
    } else {
        return -0x80 + CChar(b & ~Byte(0x80))
    }
}

public final class JsonParser: Parser {

    public class func parse(source: StaticString) -> Result {
        let begin = source.start
        let end = begin.advancedBy(Int(source.byteSize))
        return JsonParser(source.stringValue, begin, end).parse()
    }

    public class func parse(begin: UnsafePointer<Byte>, end: UnsafePointer<Byte>) -> Result {
        return JsonParser(nil, begin, end).parse()
    }

    typealias Iterator = UnsafePointer<Byte>


    let originalSource: AnyObject?
    let beg: Iterator
    let end: Iterator
    var cur: Iterator

    public var lineNumber = 1
    public var columnNumber = 1

    public init(_ source: AnyObject?, _ begin: UnsafePointer<Byte>, _ end: UnsafePointer<Byte>) {
        self.originalSource = source
        self.beg = begin
        self.end = end
        self.cur = begin
    }

    public enum Result {
        case Success(Json)
        case Error(ParseError)
    }


    func parse() -> Result {
        switch parseValue() {
        case .Success(let json):
            skipWhitespaces()
            if (cur == end) {
                return .Success(json)
            } else {
                return .Error(ExtraTokenError("extra tokens found", self))
            }
        case .Error(let error):
            return .Error(error)
        }
    }

    func parseValue() -> Result {
        skipWhitespaces()

        if cur == end {
            return .Error(InsufficientTokenError("unexpected end of tokens", self))
        }

        switch cur.memory {
        case Byte("n"):
            return parseSymbol("null", Json.NullValue)
        case Byte("t"):
            return parseSymbol("true", Json.BooleanValue(true))
        case Byte("f"):
            return parseSymbol("false", Json.BooleanValue(false))
        case Byte("-"), Byte("0") ... Byte("9"):
            return parseNumber()
        case Byte("\""):
            return parseString()
        case Byte("{"):
            return parseObject()
        case Byte("["):
            return parseArray()
        case (let c):
            return .Error(UnexpectedTokenError("unexpected token: \(c)", self))
        }
    }

    var currentSymbol: Character {
        get { return Character(UnicodeScalar(cur.memory)) }
    }

    func parseSymbol(target: StaticString, _ iftrue: @autoclosure () -> Json) -> Result {
        if expect(target) {
            return .Success(iftrue())
        } else {
            return .Error(UnexpectedTokenError("expected \"\(target)\" but \(currentSymbol)", self))
        }
    }

    func parseString() -> Result {
        assert(cur.memory == Byte("\""), "points a double quote")
        nextChar()

        var buffer = [CChar]()

        LOOP: for ; cur != end; nextChar() {
            switch cur.memory {
            case Byte("\\"):
                nextChar()
                if (cur == end) {
                    return .Error(InsufficientTokenError("unexpected end of a string literal", self))
                }
                for u in parseEscapedChar(UnicodeScalar(cur.memory)).utf8 {
                    buffer.append(byte2cchar(u))
                }
                break
            case Byte("\""): // end of the string literal
                nextChar()
                break LOOP
            default:
                buffer.append(byte2cchar(cur.memory))
            }
        }
        buffer.append(0) // trailing nul

        let s = String.fromCString(buffer)!
        return .Success(.StringValue(s))
    }

    func parseEscapedChar(c: UnicodeScalar) -> String {
        // TODO: unicode escape sequence
        return String(Character(unescapeMapping[c] ?? c))
    }

    func parseNumber() -> Result {
        let sign = expect("-") ? -1.0 : 1.0

        let start = index
        var n = Double()

        // integer
        LOOP: for ; cur != end; nextChar() {
            switch cur.memory {
            case Byte("0") ... Byte("9"):
                let d = String(UnicodeScalar(cur.memory)).toInt()!
                n = (n * 10.0) + Double(d)
            default:
                break LOOP
            }
        }

        // fraction
        if expect(".") {
            var factor = 0.1

            LOOP: for ; cur != end; nextChar() {
                switch cur.memory {
                case Byte("0") ... Byte("9"):
                    let d = String(UnicodeScalar(cur.memory)).toInt()!
                    n += (Double(d) * factor)
                    factor /= 10
                default:
                    break LOOP
                }
            }
        }

        return .Success(.NumberValue(sign * n))
    }

    func parseObject() -> Result {
        assert(cur.memory == Byte("{"), "points \"{\"")
        nextChar()

        var o = [String:Json]()

        LOOP: for ;cur != end && !expect("}"); nextChar() {
            // key
            switch parseValue() {
            case .Success(let keyValue):
                switch keyValue {
                case .StringValue(let key):
                    if !expect(":") {
                        return .Error(UnexpectedTokenError("missing colon (:)", self))
                    }

                    // value
                    switch parseValue() {
                    case .Success(let value):
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
                        return .Error(UnexpectedTokenError("missing comma (,)", self))
                    }
                default:
                    return .Error(NonStringKeyError("unexpected value for object key", self))
                }
            case (let error):
                return error
            }
        }

        return .Success(.ObjectValue(o))
    }

    func parseArray() -> Result {
        assert(cur.memory == Byte("["), "points \"[\"")
        nextChar()

        var a = Array<Json>()

        LOOP: for ;cur != end && !expect("]"); nextChar() {
            switch parseValue() {
            case .Success(let json):
                a.append(json)

                if expect(",") {
                    break
                } else if expect("]") {
                    break LOOP
                } else {
                    return .Error(UnexpectedTokenError("missing comma (,) (token: \(currentSymbol))", self))
                }
            case (let error):
                return error
            }

        }

        return .Success(.ArrayValue(a))
    }


    func expect(target: StaticString) -> Bool {
        skipWhitespaces()

        if !isIdentifier(target.start.memory) {
            // when single character
            if target.start.memory == cur.memory {
                nextChar()
                return true
            } else {
                return false
            }
        }

        let start = cur
        let l = lineNumber
        let c = columnNumber

        var p = target.start
        let endp = p.advancedBy(Int(target.byteSize))

        LOOP: for ; p != endp; p++, nextChar() {
            if !isIdentifier(cur.memory) {
                break
            }

            if p.memory != cur.memory {
                cur = start // unread
                lineNumber = l
                columnNumber = c
                return false
            }
        }

        return true
    }

    // only "true", "false", "null" are identifiers
    func isIdentifier(c: Byte) -> Bool {
        switch c {
        case Byte("a") ... Byte("z"):
            return true
        default:
            return false
        }
    }

    func nextChar() {
        cur++

        switch cur.memory {
        case Byte("\n"):
            lineNumber++
            columnNumber = 1
        default:
            columnNumber++
        }
    }

    func skipWhitespaces() {
        LOOP: for ; cur != end; nextChar() {
            switch cur.memory {
            case Byte(" "), Byte("\t"), Byte("\r"), Byte("\n"):
                break
            default:
                return
            }
        }
    }
}

// MARK: +Foundation

import Foundation

extension JsonParser {
    public class func parse(source: NSData) -> Result {
        let begin = unsafeBitCast(source.bytes, UnsafePointer<Byte>.self)
        let end = begin.advancedBy(source.length)
        return JsonParser(source, begin, end).parseValue()
    }
}
