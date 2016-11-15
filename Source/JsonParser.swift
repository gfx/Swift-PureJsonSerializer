//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/11.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//  License: The MIT License
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

internal final class JsonDeserializer: Parser {
    internal  typealias ByteSequence = [UInt8]
    internal  typealias Char = UInt8
    
    // MARK: Public Readable
    
    internal fileprivate(set) var lineNumber = 1
    internal fileprivate(set) var columnNumber = 1
    
    // MARK: Source
    
    fileprivate let source: [UInt8]
    
    // MARK: State
    
    fileprivate var cur: Int
    fileprivate let end: Int
    
    // MARK: Accessors
    
    fileprivate var currentChar: Char {
        return source[cur]
    }
    
    fileprivate var nextChar: Char {
        return source[(cur + 1)]
    }
    
    fileprivate var currentSymbol: Character {
        return Character(UnicodeScalar(currentChar))
    }
    
    // MARK: Initializer
    
    internal required convenience init<ByteSequence: Collection>(_ sequence: ByteSequence) where ByteSequence.Iterator.Element == UInt8 {
        self.init(Array(sequence))
    }
    
    internal required init(_ source: ByteSequence) {
        self.source = source
        self.cur = source.startIndex
        self.end = source.endIndex
    }
    
    // MARK: Serialize
    
    internal func deserialize() throws -> Json {
        let json = try deserializeNextValue()
        skipWhitespaces()
        
        guard cur == end else {
            throw ExtraTokenError("extra tokens found", self) as! Error
        }
        
        return json
    }
    
    fileprivate func deserializeNextValue() throws -> Json {
        skipWhitespaces()
        guard cur != end else {
            throw InsufficientTokenError("unexpected end of tokens", self) as! Error
        }
        
        switch currentChar {
        case Char(ascii: "n"):
            return try parseSymbol("null", Json.nullValue)
        case Char(ascii: "t"):
            return try parseSymbol("true", Json.booleanValue(true))
        case Char(ascii: "f"):
            return try parseSymbol("false", Json.booleanValue(false))
        case Char(ascii: "-"), Char(ascii: "0") ... Char(ascii: "9"):
            return try parseNumber()
        case Char(ascii: "\""):
            return try parseString()
        case Char(ascii: "{"):
            return try parseObject()
        case Char(ascii: "["):
            return try parseArray()
        case let c:
            throw UnexpectedTokenError("unexpected token: \(c)", self) as! Error
        }
    }
    
    fileprivate func parseSymbol(_ target: StaticString, _ iftrue:  @autoclosure () -> Json) throws -> Json {
        guard expect(target) else {
            throw UnexpectedTokenError("expected \"\(target)\" but \(currentSymbol)", self) as! Error
        }
        
        return iftrue()
    }
    
    fileprivate func parseString() throws -> Json {
        assert(currentChar == Char(ascii: "\""), "points a double quote")
        advance()
        
        var buffer = [CChar]()

        while cur != end && currentChar != Char(ascii: "\"") {
            switch currentChar {
            case Char(ascii: "\\"):
                advance()
                
                guard cur != end else {
                    throw InvalidStringError("unexpected end of a string literal", self) as! Error
                }
                
                guard let escapedChar = parseEscapedChar() else {
                    throw InvalidStringError("invalid escape sequence", self) as! Error
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
            throw InvalidStringError("missing double quote", self) as! Error
        }
        
        buffer.append(0) // trailing nul
        
        return .StringValue(String(cString: buffer))
    }
    
    fileprivate func parseEscapedChar() -> UnicodeScalar? {
        let character = UnicodeScalar(currentChar)
        
        // 'u' indicates unicode
        guard character == "u" else {
            return unescapeMapping[character] ?? character
        }
        
        guard let surrogateValue = parseEscapedUnicodeSurrogate() else { return nil }

        // two consecutive \u#### sequences represent 32 bit unicode characters
        if nextChar == Char(ascii: "\\") && source[cur.advanced(by: 2)] == Char(ascii: "u") {
                advance(); advance()
                guard let surrogatePairValue = parseEscapedUnicodeSurrogate() else { return nil }
                
                return UnicodeScalar(surrogateValue << 16 | surrogatePairValue)
        }
        
        return UnicodeScalar(surrogateValue)
    }
    fileprivate func parseEscapedUnicodeSurrogate() -> UInt32? {
        let requiredLength = 4
        
        var length = 0
        var value: UInt32 = 0
        while let d = hexToDigit(nextChar) , length < requiredLength {
            advance()
            length += 1
            
            value <<= 4
            value |= d
        }
        
        guard length == requiredLength else { return nil }
        return value
    }
    
    // number = [ minus ] int [ frac ] [ exp ]
    fileprivate func parseNumber() throws -> Json {
        let sign = expect("-") ? -1.0 : 1.0
        
        var integer: Int64 = 0
        switch currentChar {
        case Char(ascii: "0"):
            advance()
        case Char(ascii: "1") ... Char(ascii: "9"):
            while let value = digitToInt(currentChar) , cur != end {
                integer = (integer * 10) + Int64(value)
                advance()
            }
        default:
            throw InvalidNumberError("invalid token in number", self) as! Error
        }
        
        var fraction: Double = 0.0
        if expect(".") {
            var factor = 0.1
            var fractionLength = 0
            
            while let value = digitToInt(currentChar) , cur != end {
                fraction += (Double(value) * factor)
                factor /= 10
                fractionLength += 1
                
                advance()
            }
            
            guard fractionLength != 0 else {
                throw InvalidNumberError("insufficient fraction part in number", self) as! Error
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
            while let value = digitToInt(currentChar) , cur != end {
                exponent = (exponent * 10) + Int64(value)
                exponentLength += 1
                advance()
            }
            
            guard exponentLength != 0 else {
                throw InvalidNumberError("insufficient exponent part in number", self) as! Error
            }
            
            exponent *= expSign
        }
        
        return .numberValue(sign * (Double(integer) + fraction) * pow(10, Double(exponent)))
    }
    
    fileprivate func parseObject() throws -> Json {
        return try getObject()
    }
    
    /**
     There is a bug in the compiler which makes this function necessary to be called from parseObject
     */
    fileprivate func getObject() throws -> Json {
        assert(currentChar == Char(ascii: "{"), "points \"{\"")
        advance()
        skipWhitespaces()
        
        var object = [String:Json]()
        
        while cur != end && !expect("}") {
            guard case let .StringValue(key) = try deserializeNextValue() else {
                throw NonStringKeyError("unexpected value for object key", self) as! Error
            }
            
            skipWhitespaces()
            guard expect(":") else {
                throw UnexpectedTokenError("missing colon (:)", self) as! Error
            }
            skipWhitespaces()
            
            let value = try deserializeNextValue()
            object[key] = value
            
            skipWhitespaces()
            
            guard !expect("}") else {
                break
            }
            
            guard expect(",") else {
                throw UnexpectedTokenError("missing comma (,)", self) as! Error
            }
        }
        
        return .ObjectValue(object)
    }
    
    fileprivate func parseArray() throws -> Json {
        assert(currentChar == Char(ascii: "["), "points \"[\"")
        advance()
        skipWhitespaces()
        
        var a = Array<Json>()
        
        LOOP: while cur != end && !expect("]") {
            let json = try deserializeNextValue()
            skipWhitespaces()
            
            a.append(json)
            
            if expect(",") {
                continue
            } else if expect("]") {
                break LOOP
            } else {
                throw UnexpectedTokenError("missing comma (,) (token: \(currentSymbol))", self) as! Error
            }
            
        }
        
        return .ArrayValue(a)
    }
    
    fileprivate func expect(_ target: StaticString) -> Bool {
        guard cur != end else { return false }
        
        if !isIdentifier(target.utf8Start.pointee) {
            // when single character
            if target.utf8Start.pointee == currentChar {
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
        let endp = p.advanced(by: Int(target.utf8CodeUnitCount))
        while p != endp {
            if p.pointee != currentChar {
                cur = start // unread
                lineNumber = l
                columnNumber = c
                return false
            }
            
            p += 1
            advance()
        }
        
        return true
    }
    
    // only "true", "false", "null" are identifiers
    fileprivate func isIdentifier(_ c: Char) -> Bool {
        switch c {
        case Char(ascii: "a") ... Char(ascii: "z"):
            return true
        default:
            return false
        }
    }
    
    fileprivate func advance() {
        assert(cur != end, "out of range")
        cur += 1
        guard cur != end else { return }
        
        switch currentChar {
        case Char(ascii: "\n"):
            lineNumber += 1
            columnNumber = 1
        default:
            columnNumber += 1
        }
    }
    
    fileprivate func skipWhitespaces() {
        while cur != end && currentChar.isWhitespace {
            advance()
        }
    }
}

extension JsonDeserializer.Char {
    var isWhitespace: Bool {
        let type = type(of: self)
        switch self {
        case type.init(ascii: " "), type.init(ascii: "\t"), type.init(ascii: "\r"), type.init(ascii: "\n"):
            return true
        default:
            return false
        }
    }
}

extension Collection {
    func prefixUntil(_ stopCondition: (Generator.Element) -> Bool) -> Array<Generator.Element> {
        var prefix: [Generator.Element] = []
        for element in self {
            guard !stopCondition(element) else { return prefix }
            prefix.append(element)
        }
        return prefix
    }
}
