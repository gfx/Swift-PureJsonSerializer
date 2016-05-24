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

//@_exported PathIndexable
//extension JSON: PathIndexable {}

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
        switch typeEnforcementLevel {
        case .strict:
            return strictIsNull
        case .fuzzy:
            return fuzzyIsNull
        }
    }

    public var strictIsNull: Bool {
        guard case .null = self else { return false }
        return true
    }

    public var fuzzyIsNull: Bool {
        if strictIsNull {
            return true
        } else if let s = self.string {
            return s == "null"
        } else {
            return false
        }
    }
}

extension JSON {
    public var bool: Bool? {
        switch typeEnforcementLevel {
        case .strict:
            return strictBool
        case .fuzzy:
            return fuzzyBool
        }
    }

    public var strictBool: Bool? {
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

    public var fuzzyBool: Bool? {
        if let strict = strictBool {
            return strict
        } else if let n = strictNumber {
            return n > 0
        } else if let s = strictString {
            return Bool(s)
        } else {
            return nil
        }
    }
}

extension JSON {
    public var number: Double? {
        switch typeEnforcementLevel {
        case .strict:
            return strictNumber
        case .fuzzy:
            return fuzzyNumber
        }
    }

    public var strictNumber: Double? {
        guard case let .number(number) = self else {
            return nil
        }

        return number
    }

    public var fuzzyNumber: Double? {
        if let n = strictNumber {
            return n
        } else if let s = strictString {
            return Double(s)
        } else if let b = strictBool {
            return b ? 1 : 0
        } else {
            return nil
        }
    }

    public var double: Double? {
        return self.number
    }

    public var strictDouble: Double? {
        return strictNumber
    }

    public var fuzzyDouble: Double? {
        return fuzzyNumber
    }

    public var float: Float? {
        switch typeEnforcementLevel {
        case .strict:
            return strictFloat
        case .fuzzy:
            return fuzzyFloat
        }
    }

    public var strictFloat: Float? {
        return strictNumber.flatMap(Float.init)
    }

    public var fuzzyFloat: Float? {
        return fuzzyNumber.flatMap(Float.init)
    }

}

extension JSON {
    public var int: Int? {
        switch typeEnforcementLevel {
        case .strict:
            return strictInt
        case .fuzzy:
            return fuzzyInt
        }
    }

    public var strictInt: Int? {
        guard let double = self.number where double % 1 == 0 else {
            return nil
        }

        return Int(double)
    }

    public var fuzzyInt: Int? {
        if let i = strictInt {
            return i
        } else if let s = strictString {
            return Int(s)
        } else if let b = strictBool {
            return b ? 1 : 0
        } else {
            return nil
        }
    }
}

extension JSON {
    public var uint: UInt? {
        switch typeEnforcementLevel {
        case .strict:
            return strictUInt
        case .fuzzy:
            return fuzzyUInt
        }
    }

    public var strictUInt: UInt? {
        guard let intValue = strictInt where intValue >= 0 else { return nil }
        return UInt(intValue)
    }

    public var fuzzyUInt: UInt? {
        if let ui = strictUInt {
            return ui
        } else if let i = strictInt {
            return i > 0 ? UInt(i) : 0
        } else if let s = strictString {
            return UInt(s)
        } else if let b = strictBool {
            return b ? 1 : 0
        } else {
            return nil
        }
    }
}

extension JSON {
    public var string: String? {
        switch typeEnforcementLevel {
        case .strict:
            return strictString
        case .fuzzy:
            return fuzzyString
        }
    }

    public var strictString: String? {
        guard case let .string(string) = self else {
            return nil
        }

        return string
    }

    public var fuzzyString: String? {
        if let s = strictString {
            return s
        } else if let i = strictInt { // int first so if it's an int, we omit `1.0` in preference of `1`
            return i.description
        } else if let n = strictNumber {
            return n.description
        } else if let b = strictBool {
            return b.description
        } else {
            return nil
        }
    }
}

extension JSON {
    public var array: [JSON]? {
        switch typeEnforcementLevel {
        case .strict:
            return strictArray
        case .fuzzy:
            return fuzzyArray
        }
    }

    public var strictArray: [JSON]? {
        guard case let .array(array) = self else { return nil }
        return array
    }

    public var fuzzyArray: [JSON]? {
        if let a = strictArray {
            return a
        } else if let s = strictString {
            return s.characters
                .split { $0 == "," }
                .map(String.init)
                .map { JSON.string($0) }
        } else {
            return nil
        }
    }
}

extension JSON {
    public var object: [String : JSON]? {
        switch typeEnforcementLevel {
        case .strict:
            return strictObject
        case .fuzzy:
            return fuzzyObject
        }

    }

    public var strictObject: [String : JSON]? {
        guard case let .object(object) = self else { return nil }
        return object
    }

    public var fuzzyObject: [String : JSON]? {
        /*
         I'm not sure that string should map to object this way, but the goal
         of fuzzy mapping is to try and fulfill the intent of the caller.
         in this case, if a string properly maps to a dictionary, we should return it.
         */
        if let o = strictObject {
            return o
        } else if let s = strictString {
            if s.isEmpty { return [:] }

            var mutable: [String : JSON] = [:]
            s.keyValuePairs().forEach { k, v in
                mutable[k] = JSON(v)
            }

            // If our string has value, and the object doesn't,
            // didn't have an object string
            if mutable.isEmpty { return nil }
            return mutable
        } else {
            return nil
        }
    }
}

extension JSON: CustomStringConvertible {
    public var description: String {
        return serialize(DefaultJsonSerializer())
    }
}

extension JSON: CustomDebugStringConvertible {
    public var debugDescription: String {
        return serialize(DefaultJsonSerializer())
    }
}

extension JSON: Equatable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch typeEnforcementLevel {
    case .strict:
        return strictEquals(lhs: lhs, rhs)
    case .fuzzy:
        return fuzzyEquals(lhs: lhs, rhs)
    }
}

private func strictEquals(lhs: JSON, _ rhs: JSON) -> Bool {
    switch lhs {
    case .null:
        return rhs.isNull
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

private func fuzzyEquals(lhs: JSON, _ rhs: JSON) -> Bool {
    switch lhs {
    case .null:
        return rhs.isNull
    case .bool(let lhsValue):
        guard let rhsValue = rhs.fuzzyBool else { return false }
        return lhsValue == rhsValue
    case .string(let lhsValue):
        guard let rhsValue = rhs.fuzzyString else { return false }
        return lhsValue == rhsValue
    case .number(let lhsValue):
        guard let rhsValue = rhs.fuzzyNumber else { return false }
        return lhsValue == rhsValue
    case .array(let lhsValue):
        guard let rhsValue = rhs.fuzzyArray else { return false }
        return lhsValue == rhsValue
    case .object(let lhsValue):
        guard let rhsValue = rhs.fuzzyObject else { return false }
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

extension String {
    /**
     Parses `key=value` pair data separated by `&`.

     - returns: String dictionary of parsed data
     */
    private func keyValuePairs() -> [String: String] {
        var data: [String: String] = [:]

        for pair in self.split(separator: "&") {
            let tokens = pair.split(separator: "=", maxSplits: 1)
            guard
                let name = tokens.first,
                let value = tokens.last
                else { continue }
            data[name] = value
        }

        return data
    }

    private func split(separator: Character,
                       maxSplits: Int = .max,
                       omittingEmptySubsequences: Bool = true) -> [String] {
        return characters
            .split(separator: separator,
                   maxSplits: maxSplits,
                   omittingEmptySubsequences: omittingEmptySubsequences)
            .map(String.init)
    }
}
