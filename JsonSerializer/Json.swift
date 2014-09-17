//
//  Json.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import Darwin

public enum Json: Printable, Equatable {
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

    public var arrayValue: [Json] {
        get {
            switch self {
            case .NullValue:
                return []
            case .ArrayValue(let array):
                return array
            default:
                return [self]
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
                return stringify(n)
            case .StringValue(let s):
                return escapeAsJsonString(s)
            case .ArrayValue(let a):
                return stringify(a)
            case .ObjectValue(let o):
                return stringify(o)
            }
        }
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
            s += "\(escapeAsJsonString(entry.0)):\(entry.1.description)"
            if i++ != (o.count - 1) {
                s += ","
            }
        }
        
        return s + "}"
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
    public static func convertFromNilLiteral() -> Json {
        return .NullValue
    }
}

extension Json: BooleanLiteralConvertible {
    public static func convertFromBooleanLiteral(value: BooleanLiteralType) -> Json {
        return .BooleanValue(value)
    }
}

extension Json: IntegerLiteralConvertible {
    public static func convertFromIntegerLiteral(value: IntegerLiteralType) -> Json {
        return .NumberValue(Double(value))
    }
}

extension Json: FloatLiteralConvertible {
    public static func convertFromFloatLiteral(value: FloatLiteralType) -> Json {
        return .NumberValue(Double(value))
    }
}

extension Json: StringLiteralConvertible {
    public static func convertFromExtendedGraphemeClusterLiteral(value: ExtendedGraphemeClusterType) -> Json {
        return .StringValue(value)
    }

    public static func convertFromStringLiteral(value: StringLiteralType) -> Json {
        return .StringValue(value)
    }
}

extension Json: ArrayLiteralConvertible {
    public static func convertFromArrayLiteral(elements: Json...) -> Json {
        return .ArrayValue(elements)
    }
}

extension Json: DictionaryLiteralConvertible {
    public static func convertFromDictionaryLiteral(elements: (String, Json)...) -> Json {
        var dictionary = [String:Json](minimumCapacity: elements.count)
        for pair in elements {
            dictionary[pair.0] = pair.1
        }
        return .ObjectValue(dictionary)
    }
}



