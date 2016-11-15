//
//  Json.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

public enum Json: CustomStringConvertible, CustomDebugStringConvertible, Equatable {
    
    case nullValue
    case booleanValue(Bool)
    case numberValue(Double)
    case StringValue(String)
    case ArrayValue([Json])
    case ObjectValue([String:Json])

    // MARK: Initialization
    
    public init(_ value: Bool) {
        self = .booleanValue(value)
    }
    
    public init(_ value: Double) {
        self = .numberValue(value)
    }
    
    public init(_ value: String) {
        self = .StringValue(value)
    }
    
    public init(_ value: [Json]) {
        self = .ArrayValue(value)
    }
    
    public init(_ value: [String : Json]) {
        self = .ObjectValue(value)
    }
    
    // MARK: From
    
    public static func from(_ value: Bool) -> Json {
        return .booleanValue(value)
    }

    public static func from(_ value: Double) -> Json {
        return .numberValue(value)
    }

    public static func from(_ value: String) -> Json {
        return .StringValue(value)
    }

    public static func from(_ value: [Json]) -> Json {
        return .ArrayValue(value)
    }

    public static func from(_ value: [String : Json]) -> Json {
        return .ObjectValue(value)
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
    
    public static func deserialize<ByteSequence: Collection>(_ sequence: ByteSequence) throws -> Json where ByteSequence.Iterator.Element == UInt8 {
        return try JsonDeserializer(sequence).deserialize()
    }
}

extension Json {
    public enum SerializationStyle {
        case `default`
        case prettyPrint
        
        fileprivate var serializer: JsonSerializer.Type {
            switch self {
            case .default:
                return DefaultJsonSerializer.self
            case .prettyPrint:
                return PrettyJsonSerializer.self
            }
        }
    }
    
    public func serialize(_ style: SerializationStyle = .default) -> String {
        return style.serializer.init().serialize(self)
    }
}

// MARK: Convenience

extension Json {
    public var isNull: Bool {
        guard case .nullValue = self else { return false }
        return true
    }
    
    public var boolValue: Bool? {
        if case let .booleanValue(bool) = self {
            return bool
        } else if let integer = intValue , integer == 1 || integer == 0 {
            // When converting from foundation type `[String : AnyObject]`, something that I see as important, 
            // it's not possible to distinguish between 'bool', 'double', and 'int'.
            // Because of this, if we have an integer that is 0 or 1, and a user is requesting a boolean val,
            // it's fairly likely this is their desired result.
            return integer == 1
        } else {
            return nil
        }
    }

    public var floatValue: Float? {
        guard let double = doubleValue else { return nil }
        return Float(double)
    }
    
    public var doubleValue: Double? {
        guard case let .numberValue(double) = self else {
            return nil
        }
        
        return double
    }

    public var intValue: Int? {
        guard case let .numberValue(double) = self , double.truncatingRemainder(dividingBy: 1) == 0 else {
            return nil
        }
        
        return Int(double)
    }

    public var uintValue: UInt? {
        guard let intValue = intValue else { return nil }
        return UInt(intValue)
    }

    public var stringValue: String? {
        guard case let .StringValue(string) = self else {
            return nil
        }
        
        return string
    }

    public var arrayValue: [Json]? {
        guard case let .ArrayValue(array) = self else { return nil }
        return array
    }

    public var objectValue: [String : Json]? {
        guard case let .ObjectValue(object) = self else { return nil }
        return object
    }
}

extension Json {
    public subscript(index: Int) -> Json? {
        assert(index >= 0)
        guard let array = arrayValue , index < array.count else { return nil }
        return array[index]
    }

    public subscript(key: String) -> Json? {
        get {
            guard let dict = objectValue else { return nil }
            return dict[key]
        }
        set {
            guard let object = objectValue else { fatalError("Unable to set string subscript on non-object type!") }
            var mutableObject = object
            mutableObject[key] = newValue
            self = .from(mutableObject)
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
    case .nullValue:
        return rhs.isNull
    case .booleanValue(let lhsValue):
        guard let rhsValue = rhs.boolValue else { return false }
        return lhsValue == rhsValue
    case .StringValue(let lhsValue):
        guard let rhsValue = rhs.stringValue else { return false }
        return lhsValue == rhsValue
    case .numberValue(let lhsValue):
        guard let rhsValue = rhs.doubleValue else { return false }
        return lhsValue == rhsValue
    case .ArrayValue(let lhsValue):
        guard let rhsValue = rhs.arrayValue else { return false }
        return lhsValue == rhsValue
    case .ObjectValue(let lhsValue):
        guard let rhsValue = rhs.objectValue else { return false }
        return lhsValue == rhsValue
    }
}

// MARK: Literal Convertibles

extension Json: ExpressibleByNilLiteral {
    public init(nilLiteral value: Void) {
        self = .nullValue
    }
}

extension Json: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .booleanValue(value)
    }
}

extension Json: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .numberValue(Double(value))
    }
}

extension Json: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = .numberValue(Double(value))
    }
}

extension Json: ExpressibleByStringLiteral {
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self = .StringValue(value)
    }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterType) {
        self = .StringValue(value)
    }

    public init(stringLiteral value: StringLiteralType) {
        self = .StringValue(value)
    }
}

extension Json: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Json...) {
        self = .ArrayValue(elements)
    }
}

extension Json: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Json)...) {
        var object = [String : Json](minimumCapacity: elements.count)
        elements.forEach { key, value in
            object[key] = value
        }
        self = .ObjectValue(object)
    }
}
