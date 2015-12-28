//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/11.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//  License: The MIT License
//

import func Darwin.pow

public enum ParseResult {
    case Success(Json)
    case Error(ParseError)
}

public struct JsonParser {
    public typealias Result = ParseResult

    public static func parse(source: String) -> Result {
        return GenericJsonParser(source.utf8).parse()
    }

    public static func parse(source: [UInt8]) -> Result {
        return GenericJsonParser(source).parse()
    }
}

public class GenericJsonParser<ByteSequence: CollectionType where ByteSequence.Generator.Element == UInt8>: Parser {
    public typealias Source = ByteSequence
    public typealias Char = Source.Generator.Element

    public typealias Result = ParseResult

    let source: Source
    var cur: Source.Index
    let end: Source.Index

    public var lineNumber = 1
    public var columnNumber = 1

    public init(_ source: Source) {
        self.source = source
        self.cur = source.startIndex
        self.end = source.endIndex
    }

    public func parse() -> Result {
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

        switch currentChar {
        case Char(ascii: "n"):
            return parseSymbol("null", Json.NullValue)
        case Char(ascii: "t"):
            return parseSymbol("true", Json.BooleanValue(true))
        case Char(ascii: "f"):
            return parseSymbol("false", Json.BooleanValue(false))
        case Char(ascii: "-"), Char(ascii: "0") ... Char(ascii: "9"):
            return parseNumber()
        case Char(ascii: "\""):
            return parseString()
        case Char(ascii: "{"):
            return parseObject()
        case Char(ascii: "["):
            return parseArray()
        case (let c):
            return .Error(UnexpectedTokenError("unexpected token: \(c)", self))
        }
    }

    var currentChar: Char {
        return source[cur]
    }

    var nextChar: Char {
        return source[cur.successor()]
    }

    var currentSymbol: Character {
        get { return Character(UnicodeScalar(currentChar)) }
    }

    func parseSymbol(target: StaticString, @autoclosure _ iftrue:  () -> Json) -> Result {
        if expect(target) {
            return .Success(iftrue())
        } else {
            return .Error(UnexpectedTokenError("expected \"\(target)\" but \(currentSymbol)", self))
        }
    }

    func parseString() -> Result {
        assert(currentChar == Char(ascii: "\""), "points a double quote")
        advance()

        var buffer = [CChar]()

        LOOP: for ; cur != end; advance() {
            switch currentChar {
            case Char(ascii: "\\"):
                advance()
                if (cur == end) {
                    return .Error(InvalidStringError("unexpected end of a string literal", self))
                }

                if let c = parseEscapedChar() {
                    for u in String(c).utf8 {
                        buffer.append(CChar(bitPattern: u))
                    }
                } else {
                    return .Error(InvalidStringError("invalid escape sequence", self))
                }
                break
            case Char(ascii: "\""): // end of the string literal
                break LOOP
            default:
                buffer.append(CChar(bitPattern: currentChar))
            }
        }

        if !expect("\"") {
            return .Error(InvalidStringError("missing double quote", self))
        }

        buffer.append(0) // trailing nul

        let s = String.fromCString(buffer)!
        return .Success(.StringValue(s))
    }

    func parseEscapedChar() -> UnicodeScalar? {
        let c = UnicodeScalar(currentChar)
        if c == "u" { // Unicode escape sequence
            var length = 0 // 2...8
            var value: UInt32 = 0
            while let d = hexToDigit(nextChar) {
                advance()
                length++

                if length > 8 {
                    break
                }

                value = (value << 4) | d
            }
            if length < 2 {
                return nil
            }
            // TODO: validate the value
            return UnicodeScalar(value)
        } else {
            let c = UnicodeScalar(currentChar)
            return unescapeMapping[c] ?? c
        }
    }

    // number = [ minus ] int [ frac ] [ exp ]
    func parseNumber() -> Result {
        let sign = expect("-") ? -1.0 : 1.0

        var integer: Int64 = 0
        switch currentChar {
        case Char(ascii: "0"):
            advance()
        case Char(ascii: "1") ... Char(ascii: "9"):
            for ; cur != end; advance() {
                if let value = digitToInt(currentChar) {
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

            for ; cur != end; advance() {
                if let value = digitToInt(currentChar) {
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
            for ; cur != end; advance() {
                if let value = digitToInt(currentChar) {
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
        assert(currentChar == Char(ascii: "{"), "points \"{\"")
        advance()
        skipWhitespaces()

        var o = [String:Json]()

        LOOP: while cur != end && !expect("}") {
            // key
            switch parseValue() {
            case .Success(let keyValue):
                switch keyValue {
                case .StringValue(let key):
                    skipWhitespaces()
                    if !expect(":") {
                        return .Error(UnexpectedTokenError("missing colon (:)", self))
                    }
                    skipWhitespaces()

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
        assert(currentChar == Char(ascii: "["), "points \"[\"")
        advance()
        skipWhitespaces()

        var a = Array<Json>()

        LOOP: while cur != end && !expect("]") {
            switch parseValue() {
            case .Success(let json):
                skipWhitespaces()

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
        if cur == end {
            return false
        }

        if !isIdentifier(target.utf8Start.memory) {
            // when single character
            if target.utf8Start.memory == currentChar {
                advance()
                return true
            } else {
                return false
            }
        }

        let start = cur
        let l = lineNumber
        let c = columnNumber

        var p = target.utf8Start
        let endp = p.advancedBy(Int(target.byteSize))

        LOOP: for ; p != endp; p++, advance() {
            if p.memory != currentChar {
                cur = start // unread
                lineNumber = l
                columnNumber = c
                return false
            }
        }

        return true
    }

    // only "true", "false", "null" are identifiers
    func isIdentifier(c: Char) -> Bool {
        switch c {
        case Char(ascii: "a") ... Char(ascii: "z"):
            return true
        default:
            return false
        }
    }

    func advance() {
        assert(cur != end, "out of range")
        cur++

        if cur != end {
            switch currentChar {
            case Char(ascii: "\n"):
                lineNumber++
                columnNumber = 1
            default:
                columnNumber++
            }
        }
    }

    func skipWhitespaces() {
        LOOP: for ; cur != end; advance() {
            switch currentChar {
            case Char(ascii: " "), Char(ascii: "\t"), Char(ascii: "\r"), Char(ascii: "\n"):
                break
            default:
                return
            }
        }
    }
}
