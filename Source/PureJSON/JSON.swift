//
//  JSON.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

// MARK: Type Enforcement

public enum TypeEnforcementLevel {
    case strict
    case fuzzy

    public var isStrict: Bool {
        return self == .strict
    }

    public var isFuzzy: Bool {
        return self == .fuzzy
    }
}

public var typeEnforcementLevel: TypeEnforcementLevel = .fuzzy

@_exported import PathIndexable
extension JSON: PathIndexable {}

public typealias Json = JSON

// MARK: JSON

public enum JSON {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSON])
    case object([String:JSON])
}

// MARK: Initialization

extension JSON {
    public init(_ value: Bool) {
        self = .bool(value)
    }

    public init(_ value: Double) {
        self = .number(value)
    }

    public init(_ value: String) {
        self = .string(value)
    }

    public init(_ value: [String : JSON]) {
        self = .object(value)
    }

    public init<T: Integer>(_ value: T) {
        self = .number(Double(value.toIntMax()))
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
        return try JsonDeserializer(source.utf8).deserialize()
    }
    
    public static func deserialize(_ source: [UInt8]) throws -> JSON {
        return try JsonDeserializer(source).deserialize()
    }
    
    public static func deserialize<ByteSequence: Collection where ByteSequence.Iterator.Element == UInt8>(_ sequence: ByteSequence) throws -> JSON {
        return try JsonDeserializer(sequence).deserialize()
    }
}

extension Json {
    public func serialize(_ serializer: JsonSerializer) -> String {
        return serializer.serialize(self)
    }
}

extension JSON {
    public enum SerializationStyle {
        case Default
        case PrettyPrint
        
        private var serializer: JsonSerializer.Type {
            switch self {
            case .Default:
                return DefaultJsonSerializer.self
            case .PrettyPrint:
                return PrettyJsonSerializer.self
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
        case let .number(n) where n == 0:
            return true
        case let .array(a) where a.isEmpty:
            return true
        case let .object(o) where o.isEmpty:
            return true
        default:
            return false
        }
    }
}

extension JSON {
    public var bool: Bool? {
        switch self {
        case let .bool(b):
            return b
        case let .string(s):
            return Bool(s)
        case let .number(n) where n == 0 || n == 1:
            return n == 1
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
            return n
        case let .string(s):
            return Double(s)
        case let .bool(b):
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
        return self.number.flatMap(Int.init)
    }
}

extension JSON {
    public var uint: UInt? {
        guard let n = self.number where n >= 0 else {
            return nil
        }
        return UInt(n)
    }
}

extension JSON {
    public var string: String? {
        switch self {
        case let .string(s):
            return s
        case let .number(n):
            return n.description
        case let .bool(b):
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
        return serialize(DefaultJsonSerializer())
    }
}

extension JSON: CustomDebugStringConvertible {
    public var debugDescription: String {
        return serialize(PrettyJsonSerializer())
    }
}

extension JSON: Equatable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch lhs {
    case .null:
        guard case .null = rhs else { return false }
        return true
    case .bool(let lhsValue):
        guard case .bool(let rhsValue) = rhs else { return false }
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
        self = .bool(value)
    }
}

extension JSON: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(Double(value))
    }
}

extension JSON: FloatLiteralConvertible {
    public init(floatLiteral value: FloatLiteralType) {
        self = .number(Double(value))
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
