//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/11.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//  License: The MIT License
//

import Darwin

// C-like conversion from Byte to CChar
func byte2cchar(b: Byte) -> CChar {
    if b < 0x80 {
        return CChar(b)
    } else {
        return -0x80 + CChar(b & ~Byte(0x80))
    }
}

public class JsonParser: Parser {

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

                if let c = parseEscapedChar() {
                    for u in String(c).utf8 {
                        buffer.append(byte2cchar(u))
                    }
                } else {
                    return .Error(InvalidEscapeSequenceError("invalid escape sequence", self))
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

    func parseEscapedChar() -> UnicodeScalar? {
        let c = UnicodeScalar(cur.memory)
        if c == "u" { // Unicode escape sequence
            var length = 0 // 2...8
            var value: UInt32 = 0
            while let d = hexToDigit((cur+1).memory) {
                nextChar()
                length++

                if length > 8 {
                    break
                }

                value = (value << 4) | d
            }
            if length < 2 {
                return nil
            }
            return UnicodeScalar(value)
        } else {
            let c = UnicodeScalar(cur.memory)
            return unescapeMapping[c] ?? c
        }
    }

    // number = [ minus ] int [ frac ] [ exp ]
    func parseNumber() -> Result {
        let sign = expect("-") ? -1.0 : 1.0

        var integer: Int64 = 0
        switch cur.memory {
        case Byte("0"):
            nextChar()
        case Byte("1") ... Byte("9"):
            for ; cur != end; nextChar() {
                if let value = digitToInt(cur.memory) {
                    integer = (integer * 10) + Int64(value)
                } else {
                    break
                }
            }
        default:
            return .Error(InvalidNumberError("invalid token in number", self))
        }

        if integer != Int64(Double(integer)) {
            // TODO
            //return .Error(InvalidNumberError("too much integer part in number", self))
        }

        var fraction: Double = 0.0
        if expect(".") {
            var factor = 0.1
            var fractionLength = 0

            for ; cur != end; nextChar() {
                if let value = digitToInt(cur.memory) {
                    fraction += (Double(value) * factor)
                    factor /= 10
                    fractionLength++
                } else {
                    break
                }
            }

            if fractionLength == 0 {
                return .Error(InvalidNumberError("insufficient fraction part in number", self))
            }
        }

        var exponent: Int64 = 0
        if expect("e") || expect("E") {
            var expSign: Int64 = 1
            if expect("-") {
                expSign = -1
            } else if expect("+") {
                // do nothing
            }

            exponent = 0

            var exponentLength = 0
            for ; cur != end; nextChar() {
                if let value = digitToInt(cur.memory) {
                    exponent = (exponent * 10) + Int64(value)
                    exponentLength++
                } else {
                    break
                }
            }
            if exponentLength == 0 {
                return .Error(InvalidNumberError("insufficient exponent part in number", self))
            }

            exponent *= expSign
        }

        //println("nuber: \(sign) * (\(integer) + \(fraction)) * pow(10, \(exponent))")
        return .Success(.NumberValue(sign * (Double(integer) + fraction) * pow(10, Double(exponent))))
    }

    func parseObject() -> Result {
        assert(cur.memory == Byte("{"), "points \"{\"")
        nextChar()

        var o = [String:Json]()

        LOOP: while cur != end && !expect("}") {
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

        LOOP: while cur != end && !expect("]") {
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
