//
//  JSON.swift
//  JSONSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import C7
public typealias JSON = C7.JSON

extension JSON.Number {
    public var double: Double {
        switch self {
        case let .double(d):
            return d
        case let .integer(i):
            return Double(i)
        case let .unsignedInteger(u):
            return Double(u)
        }
    }

    public var int: Int {
        switch self {
        case let .double(d):
            return Int(d)
        case let .integer(i):
            return i
        case let .unsignedInteger(u):
            if u < UInt(Int.max) {
                return Int(u)
            } else {
                return Int.max
            }
        }
    }

    public var uint: UInt {
        switch self {
        case let .double(d) where d >= 0:
            return UInt(d)
        case let .integer(i) where i >= 0:
            return UInt(i)
        case let .unsignedInteger(u):
            return u
        default:
            return 0
        }
    }
}

extension JSON.Number: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .double(d):
            if d % 1 == 0 {
                return Int(d).description
            } else {
                return d.description
            }
        case let .integer(i):
            return i.description
        case let .unsignedInteger(u):
            return u.description
        }
    }
}

extension JSON.Number: Equatable {}

public func == (lhs: JSON.Number, rhs: JSON.Number) -> Bool {
    switch lhs {
    case let .double(d):
        return d == rhs.double
    case let .integer(i):
        return i == rhs.int
    case let .unsignedInteger(u):
        return u == rhs.uint
    }
}

@_exported import PathIndexable
extension JSON: PathIndexable {}

// MARK: Initialization

extension JSON {
    public init(_ value: Bool) {
        self = .boolean(value)
    }

    public init(_ value: Double) {
        self = .number(.double(value))
    }

    public init(_ value: String) {
        self = .string(value)
    }

    public init(_ value: [String : JSON]) {
        self = .object(value)
    }

    public init<T: SignedInteger>(_ value: T) {
        let int = Int(value.toIntMax())
        self = .number(.integer(int))
    }

    public init<T: UnsignedInteger>(_ value: T) {
        let uint = UInt(value.toUIntMax())
        self = .number(.unsignedInteger(uint))
    }

    public init<T : Sequence where T.Iterator.Element == JSON>(_ value: T) {
        let array = [JSON](value)
        self = .array(array)
    }

    public init<T : Sequence where T.Iterator.Element == (key: String, value: JSON)>(_ seq: T) {
        var obj: [String : JSON] = [:]
        seq.forEach { key, val in
            obj[key] = val
        }
        self = .object(obj)
    }
}

// MARK: Serialization

extension JSON {
    public static func deserialize(_ source: String) throws -> JSON {
        return try JSONDeserializer(source.utf8).deserialize()
    }
    
    public static func deserialize(_ source: [UInt8]) throws -> JSON {
        return try JSONDeserializer(source).deserialize()
    }
    
    public static func deserialize<ByteSequence: Collection where ByteSequence.Iterator.Element == UInt8>(_ sequence: ByteSequence) throws -> JSON {
        return try JSONDeserializer(sequence).deserialize()
    }
}

extension JSON {
    public func serialize(_ serializer: JSONSerializer) -> String {
        return serializer.serialize(self)
    }
}

extension JSON {
    public enum SerializationStyle {
        case Default
        case PrettyPrint
        
        private var serializer: JSONSerializer.Type {
            switch self {
            case .Default:
                return DefaultJSONSerializer.self
            case .PrettyPrint:
                return PrettyJSONSerializer.self
            }
        }
    }
    
    public func serialize(_ style: SerializationStyle = .Default) -> String {
        return style.serializer.init().serialize(self)
    }
}

// MARK: Convenience

extension JSON {
    public var isNull: Bool {
        switch self {
        case .null:
            return true
        case let .string(s) where s.lowercased() == "null":
            return true
        default:
            return false
        }
    }
}

extension JSON {
    public var bool: Bool? {
        switch self {
        case let .boolean(b):
            return b
        case let .string(s):
            return Bool(s)
        case let .number(n) where n.double == 0 || n.double == 1:
            return n.double == 1
        case .null:
            return false
        default:
            return nil
        }
    }
}

extension JSON {
    public var number: Double? {
        switch self {
        case let .number(n):
            return n.double
        case let .string(s):
            return Double(s)
        case let .boolean(b):
            return b ? 1 : 0
        case .null:
            return 0
        default:
            return nil
        }
    }

    public var double: Double? {
        return self.number
    }

    public var float: Float? {
        return self.number.flatMap(Float.init)
    }

}

extension JSON {
    public var int: Int? {
        switch self {
        case let .number(n):
            return n.int
        case let .string(s):
            return Int(s)
        case let .boolean(b):
            return b ? 1 : 0
        case .null:
            return 0
        default:
            return nil
        }
    }
}

extension JSON {
    public var uint: UInt? {
        switch self {
        case let .number(n):
            return n.uint
        case let .string(s):
            return UInt(s)
        case let .boolean(b):
            return b ? 1 : 0
        case .null:
            return 0
        default:
            return nil
        }
    }
}

extension JSON {
    public var string: String? {
        switch self {
        case let .string(s):
            return s
        case let .number(n):
            return n.description
        case let .boolean(b):
            return b.description
        case .null:
            return "null"
        default:
            return nil
        }
    }
}

extension JSON {
    public var array: [JSON]? {
        guard case let .array(a) = self else {
            return nil
        }
        return a
    }
}

extension JSON {
    public var object: [String : JSON]? {
        guard case let .object(o) = self else {
            return nil
        }
        return o
    }
}

extension JSON: CustomStringConvertible {
    public var description: String {
        return serialize(DefaultJSONSerializer())
    }
}

extension JSON: CustomDebugStringConvertible {
    public var debugDescription: String {
        return serialize(PrettyJSONSerializer())
    }
}

extension JSON: Equatable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch lhs {
    case .null:
        guard case .null = rhs else { return false }
        return true
    case .boolean(let lhsValue):
        guard case .boolean(let rhsValue) = rhs else { return false }
        return lhsValue == rhsValue
    case .string(let lhsValue):
        guard case .string(let rhsValue) = rhs else { return false }
        return lhsValue == rhsValue
    case .number(let lhsValue):
        guard case .number(let rhsValue) = rhs else { return false }
        return lhsValue == rhsValue
    case .array(let lhsValue):
        guard case .array(let rhsValue) = rhs else { return false }
        return lhsValue == rhsValue
    case .object(let lhsValue):
        guard case .object(let rhsValue) = rhs else { return false }
        return lhsValue == rhsValue
    }
}

// MARK: Literal Convertibles

extension JSON: NilLiteralConvertible {
    public init(nilLiteral value: Void) {
        self = .null
    }
}

extension JSON: BooleanLiteralConvertible {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .boolean(value)
    }
}

extension JSON: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(.integer(value))
    }
}

extension JSON: FloatLiteralConvertible {
    public init(floatLiteral value: FloatLiteralType) {
        self = .number(.double(value))
    }
}

extension JSON: StringLiteralConvertible {
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self = .string(value)
    }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterType) {
        self = .string(value)
    }

    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension JSON: ArrayLiteralConvertible {
    public init(arrayLiteral elements: JSON...) {
        self = .array(elements)
    }
}

extension JSON: DictionaryLiteralConvertible {
    public init(dictionaryLiteral elements: (String, JSON)...) {
        var object = [String : JSON](minimumCapacity: elements.count)
        elements.forEach { key, value in
            object[key] = value
        }
        self = .object(object)
    }
}

// MARK: Utility

extension Bool {
    /**
     This function seeks to replicate the expected behavior of `var boolValue: Bool` on `NSString`.  Any variant of `yes`, `y`, `true`, `t`, or any numerical value greater than 0 will be considered `true`
     */
    private init(_ string: String) {
        let cleaned = string
            .lowercased()
            .characters
            .first ?? "n"

        switch cleaned {
        case "t", "y", "1":
            self = true
        default:
            if let int = Int(String(cleaned)) where int > 0 {
                self = true
            } else {
                self = false
            }

        }
    }
}
