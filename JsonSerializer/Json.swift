//
//  Json.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import func Darwin.atof

public enum Json: CustomStringConvertible, CustomDebugStringConvertible, Equatable {
    case NullValue
    case BooleanValue(Bool)
    case NumberValue(Double)
    case StringValue(String)
    case ArrayValue([Json])
    case ObjectValue([String:Json])

    static func from(value: Bool) -> Json {
        return .BooleanValue(value)
    }

    static func from(value: Double) -> Json {
        return .NumberValue(value)
    }

    static func from(value: String) -> Json {
        return .StringValue(value)
    }

    static func from(value: [Json]) -> Json {
        return .ArrayValue(value)
    }

    static func from(value: [String:Json]) -> Json {
        return .ObjectValue(value)
    }

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

    public var arrayValue: [Json] {
        get {
            switch self {
            case .NullValue:
                return []
            case .ArrayValue(let array):
                return array
            default:
                return []
            }
        }
    }

    public var dictionaryValue: [String:Json] {
        get {
            switch self {
            case .NullValue:
                return [:]
            case .ObjectValue(let dictionary):
                return dictionary
            default:
                return [:]
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
        get { return serialize(DefaultJsonSerializer()) }
    }

    public var debugDescription: String {
        get { return serialize(PrettyJsonSerializer()) }
    }

    public func serialize(serializer: JsonSerializer) -> String {
        return serializer.serialize(self)
    }
}


public func ==(lhs: Json, rhs: Json) -> Bool {
    switch lhs {
    case .NullValue:
        switch rhs {
        case .NullValue:
            return true
        default:
            return false
        }
    case .BooleanValue(let lhsValue):
        switch rhs {
        case .BooleanValue(let rhsValue):
            return lhsValue == rhsValue
        default:
            return false
        }
    case .StringValue(let lhsValue):
        switch rhs {
        case .StringValue(let rhsValue):
            return lhsValue == rhsValue
        default:
            return false
        }
    case .NumberValue(let lhsValue):
        switch rhs {
        case .NumberValue(let rhsValue):
            return lhsValue == rhsValue
        default:
            return false
        }
    case .ArrayValue(let lhsValue):
        switch rhs {
        case .ArrayValue(let rhsValue):
            return lhsValue == rhsValue
        default:
            return false
        }
    case .ObjectValue(let lhsValue):
        switch rhs {
        case .ObjectValue(let rhsValue):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}


extension Json: NilLiteralConvertible {
    public init(nilLiteral value: Void) {
        self = .NullValue
    }
}

extension Json: BooleanLiteralConvertible {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .BooleanValue(value)
    }
}

extension Json: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .NumberValue(Double(value))
    }
}

extension Json: FloatLiteralConvertible {
    public init(floatLiteral value: FloatLiteralType) {
        self = .NumberValue(Double(value))
    }
}

extension Json: StringLiteralConvertible {
    public typealias UnicodeScalarLiteralType = String
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self = .StringValue(value)
    }

    public typealias ExtendedGraphemeClusterLiteralType = String
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterType) {
        self = .StringValue(value)
    }

    public init(stringLiteral value: StringLiteralType) {
        self = .StringValue(value)
    }
}

extension Json: ArrayLiteralConvertible {
    public init(arrayLiteral elements: Json...) {
        self = .ArrayValue(elements)
    }
}

extension Json: DictionaryLiteralConvertible {
    public init(dictionaryLiteral elements: (String, Json)...) {
        var dictionary = [String:Json](minimumCapacity: elements.count)
        for pair in elements {
            dictionary[pair.0] = pair.1
        }
        self = .ObjectValue(dictionary)
    }
}



