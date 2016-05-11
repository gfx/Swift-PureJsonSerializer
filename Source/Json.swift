//
//  Json.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

public enum Json: CustomStringConvertible, CustomDebugStringConvertible, Equatable {
    
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([Json])
    case object([String:Json])

    // MARK: Initialization
    
    public init(_ value: Bool) {
        self = .bool(value)
    }

    public init(_ value: Int) {
        let double = Double(value)
        self = .number(double)
    }
    
    public init(_ value: Double) {
        self = .number(value)
    }
    
    public init(_ value: String) {
        self = .string(value)
    }
    
    public init(_ value: [Json]) {
        self = .array(value)
    }
    
    public init(_ value: [String : Json]) {
        self = .object(value)
    }
}

// MARK: Serialization

extension Json {
    public static func deserialize(_ source: String) throws -> Json {
        return try JsonDeserializer(source.utf8).deserialize()
    }
    
    public static func deserialize(_ source: [UInt8]) throws -> Json {
        return try JsonDeserializer(source).deserialize()
    }
    
    public static func deserialize<ByteSequence: Collection where ByteSequence.Iterator.Element == UInt8>(_ sequence: ByteSequence) throws -> Json {
        return try JsonDeserializer(sequence).deserialize()
    }
}

extension Json {
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

extension Json {
    public var isNull: Bool {
        guard case .null = self else { return false }
        return true
    }
    
    public var bool: Bool? {
        if case let .bool(bool) = self {
            return bool
        } else if let integer = int where integer == 1 || integer == 0 {
            // When converting from foundation type `[String : AnyObject]`, something that I see as important, 
            // it's not possible to distinguish between 'bool', 'double', and 'int'.
            // Because of this, if we have an integer that is 0 or 1, and a user is requesting a boolean val,
            // it's fairly likely this is their desired result.
            return integer == 1
        } else {
            return nil
        }
    }

    public var float: Float? {
        guard let double = double else { return nil }
        return Float(double)
    }
    
    public var double: Double? {
        guard case let .number(double) = self else {
            return nil
        }
        
        return double
    }

    public var int: Int? {
        guard case let .number(double) = self where double % 1 == 0 else {
            return nil
        }
        
        return Int(double)
    }

    public var uint: UInt? {
        guard let intValue = int else { return nil }
        return UInt(intValue)
    }

    public var string: String? {
        guard case let .string(string) = self else {
            return nil
        }
        
        return string
    }

    public var array: [Json]? {
        guard case let .array(array) = self else { return nil }
        return array
    }

    public var object: [String : Json]? {
        guard case let .object(object) = self else { return nil }
        return object
    }
}

extension Json {
    public subscript(index: Int) -> Json? {
        assert(index >= 0)
        guard let array = self.array where index < array.count else { return nil }
        return array[index]
    }

    public subscript(key: String) -> Json? {
        get {
            guard let dict = self.object else { return nil }
            return dict[key]
        }
        set {
            guard let object = self.object else { fatalError("Unable to set string subscript on non-object type!") }
            var mutableObject = object
            mutableObject[key] = newValue
            self = .init(mutableObject)
        }
    }
}

extension Json {
    public var description: String {
        return serialize(DefaultJsonSerializer())
    }

    public var debugDescription: String {
        return serialize(PrettyJsonSerializer())
    }
}

extension Json {
    public func serialize(_ serializer: JsonSerializer) -> String {
        return serializer.serialize(self)
    }
}


public func ==(lhs: Json, rhs: Json) -> Bool {
    switch lhs {
    case .null:
        return rhs.isNull
    case .bool(let lhsValue):
        guard let rhsValue = rhs.bool else { return false }
        return lhsValue == rhsValue
    case .string(let lhsValue):
        guard let rhsValue = rhs.string else { return false }
        return lhsValue == rhsValue
    case .number(let lhsValue):
        guard let rhsValue = rhs.double else { return false }
        return lhsValue == rhsValue
    case .array(let lhsValue):
        guard let rhsValue = rhs.array else { return false }
        return lhsValue == rhsValue
    case .object(let lhsValue):
        guard let rhsValue = rhs.object else { return false }
        return lhsValue == rhsValue
    }
}

// MARK: Literal Convertibles

extension Json: NilLiteralConvertible {
    public init(nilLiteral value: Void) {
        self = .null
    }
}

extension Json: BooleanLiteralConvertible {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension Json: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(Double(value))
    }
}

extension Json: FloatLiteralConvertible {
    public init(floatLiteral value: FloatLiteralType) {
        self = .number(Double(value))
    }
}

extension Json: StringLiteralConvertible {
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

extension Json: ArrayLiteralConvertible {
    public init(arrayLiteral elements: Json...) {
        self = .array(elements)
    }
}

extension Json: DictionaryLiteralConvertible {
    public init(dictionaryLiteral elements: (String, Json)...) {
        var object = [String : Json](minimumCapacity: elements.count)
        elements.forEach { key, value in
            object[key] = value
        }
        self = .object(object)
    }
}
