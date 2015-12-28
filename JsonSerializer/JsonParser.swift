//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/11.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//  License: The MIT License
//

import func Darwin.pow

public struct JsonParser {
    public static func parse(source: String) throws -> Json {
        return try GenJsonParser(source.utf8).parse()
    }
    
    public static func parse(source: [UInt8]) throws -> Json {
        return try GenJsonParser(source).parse()
    }
}

public final class GenJsonParser: Parser {
    public typealias ByteSequence = [UInt8]
    public typealias Char = UInt8
    
    // MARK: Public Readable
    
    public private(set) var lineNumber = 1
    public private(set) var columnNumber = 1
    
    // MARK: Source
    
    private let source: [UInt8]
    
    // MARK: State
    
    private var cur: Int
    private let end: Int
    
    // MARK: Accessors
    
    private var currentChar: Char {
        return source[cur]
    }
    
    private var nextChar: Char {
        return source[cur.successor()]
    }
    
    private var currentSymbol: Character {
        return Character(UnicodeScalar(currentChar))
    }
    
    // MARK: Initializer
    
    public convenience init<ByteSequence: CollectionType where ByteSequence.Generator.Element == UInt8>(_ sequence: ByteSequence) {
        self.init(Array(sequence))
    }
    
    public init(_ source: ByteSequence) {
        self.source = source
        self.cur = source.startIndex
        self.end = source.endIndex
    }
    
    // MARK: Serialize
    
    public func parse() throws -> Json {
        let json = try parseValue()
        skipWhitespaces()
        
        guard cur == end else {
            throw ExtraTokenError("extra tokens found", self)
        }
        
        return json
    }
    
    private func parseValue() throws -> Json {
        skipWhitespaces()
        guard cur != end else {
            throw InsufficientTokenError("unexpected end of tokens", self)
        }
        
        switch currentChar {
        case Char(ascii: "n"):
            return try parseSymbol("null", Json.NullValue)
        case Char(ascii: "t"):
            return try parseSymbol("true", Json.BooleanValue(true))
        case Char(ascii: "f"):
            return try parseSymbol("false", Json.BooleanValue(false))
        case Char(ascii: "-"), Char(ascii: "0") ... Char(ascii: "9"):
            return try parseNumber()
        case Char(ascii: "\""):
            return try parseString()
        case Char(ascii: "{"):
            return try parseObject()
        case Char(ascii: "["):
            return try parseArray()
        case let c:
            throw UnexpectedTokenError("unexpected token: \(c)", self)
        }
    }
    
    private func parseSymbol(target: StaticString, @autoclosure _ iftrue:  () -> Json) throws -> Json {
        if expect(target) {
            return iftrue()
        } else {
            throw UnexpectedTokenError("expected \"\(target)\" but \(currentSymbol)", self)
        }
    }
    
    private func parseString() throws -> Json {
        assert(currentChar == Char(ascii: "\""), "points a double quote")
        advance()
        
        var buffer = [CChar]()
        
        while cur != end && currentChar != Char(ascii: "\"") {
            switch currentChar {
            case Char(ascii: "\\"):
                advance()
                
                guard cur != end else {
                    throw InvalidStringError("unexpected end of a string literal", self)
                }
                
                guard let escapedChar = parseEscapedChar() else {
                    throw InvalidStringError("invalid escape sequence", self)
                }
                
                String(escapedChar).utf8.forEach {
                    buffer.append(CChar(bitPattern: $0))
                }
            default:
                buffer.append(CChar(bitPattern: currentChar))
            }
            
            advance()
        }
        
        guard expect("\"") else {
            throw InvalidStringError("missing double quote", self)
        }
        
        buffer.append(0) // trailing nul
        
        guard let string = String.fromCString(buffer) else {
            throw InvalidStringError("Unable to parse CString", self)
        }
        
        return .StringValue(string)
    }
    
    private func parseEscapedChar() -> UnicodeScalar? {
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
    private func parseNumber() throws -> Json {
        let sign = expect("-") ? -1.0 : 1.0
        
        var integer: Int64 = 0
        switch currentChar {
        case Char(ascii: "0"):
            advance()
        case Char(ascii: "1") ... Char(ascii: "9"):
            while let value = digitToInt(currentChar) where cur != end {
                integer = (integer * 10) + Int64(value)
                advance()
            }
        default:
            throw InvalidNumberError("invalid token in number", self)
        }
        
        if integer != Int64(Float80(integer)) {
            // TODO: Verify implications of Float80
            throw InvalidNumberError("too much integer part in number", self)
        }
        
        var fraction: Double = 0.0
        if expect(".") {
            var factor = 0.1
            var fractionLength = 0
            
            while let value = digitToInt(currentChar) where cur != end {
                fraction += (Double(value) * factor)
                factor /= 10
                fractionLength++
                
                advance()
            }
            
            guard fractionLength != 0 else {
                throw InvalidNumberError("insufficient fraction part in number", self)
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
            while let value = digitToInt(currentChar) where cur != end {
                exponent = (exponent * 10) + Int64(value)
                exponentLength++
                advance()
            }
            
            guard exponentLength != 0 else {
                throw InvalidNumberError("insufficient exponent part in number", self)
            }
            
            exponent *= expSign
        }
        
        return .NumberValue(sign * (Double(integer) + fraction) * pow(10, Double(exponent)))
    }
    
    private func parseObject() throws -> Json {
        return try getObject()
    }
    
    /**
     There is a bug in the compiler which makes this function necessary to be called from parseObject
     */
    private func getObject() throws -> Json {
        assert(currentChar == Char(ascii: "{"), "points \"{\"")
        advance()
        skipWhitespaces()
        
        var object = [String:Json]()
        
        while cur != end && !expect("}") {
            guard case let .StringValue(key) = try parseValue() else {
                throw NonStringKeyError("unexpected value for object key", self)
            }
            
            skipWhitespaces()
            guard expect(":") else {
                throw UnexpectedTokenError("missing colon (:)", self)
            }
            skipWhitespaces()
            
            let value = try parseValue()
            object[key] = value
            
            skipWhitespaces()
            
            guard !expect("}") else {
                break
            }
            
            guard expect(",") else {
                throw UnexpectedTokenError("missing comma (,)", self)
            }
        }
        
        return .ObjectValue(object)
    }
    
    private func parseArray() throws -> Json {
        assert(currentChar == Char(ascii: "["), "points \"[\"")
        advance()
        skipWhitespaces()
        
        var a = Array<Json>()
        
        LOOP: while cur != end && !expect("]") {
            let json = try parseValue()
            skipWhitespaces()
            
            a.append(json)
            
            if expect(",") {
                continue
            } else if expect("]") {
                break LOOP
            } else {
                throw UnexpectedTokenError("missing comma (,) (token: \(currentSymbol))", self)
            }
            
        }
        
        return .ArrayValue(a)
    }
    
    private func expect(target: StaticString) -> Bool {
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
        while p != endp {
            if p.memory != currentChar {
                cur = start // unread
                lineNumber = l
                columnNumber = c
                return false
            }
            
            p++
            advance()
        }
        
        return true
    }
    
    // only "true", "false", "null" are identifiers
    private func isIdentifier(c: Char) -> Bool {
        switch c {
        case Char(ascii: "a") ... Char(ascii: "z"):
            return true
        default:
            return false
        }
    }
    
    private func advance() {
        assert(cur != end, "out of range")
        cur++
        guard cur != end else { return }
        
        switch currentChar {
        case Char(ascii: "\n"):
            lineNumber++
            columnNumber = 1
        default:
            columnNumber++
        }
    }
    
    private func skipWhitespaces() {
        while cur != end && currentChar.isWhitespace {
            advance()
        }
    }
}

extension GenJsonParser.Char {
    var isWhitespace: Bool {
        let type = self.dynamicType
        switch self {
        case type.init(ascii: " "), type.init(ascii: "\t"), type.init(ascii: "\r"), type.init(ascii: "\n"):
            return true
        default:
            return false
        }
    }
}
