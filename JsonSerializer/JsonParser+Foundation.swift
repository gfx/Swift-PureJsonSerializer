//
//  JsonSerializer+Foundation.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import Foundation

public extension Json {
    var anyValue: AnyObject {
        switch self {
        case .object(let ob):
            var mapped: [String : AnyObject] = [:]
            ob.forEach { key, val in
                mapped[key] = val.anyValue
            }
            return mapped
        case .array(let array):
            return array.map { $0.anyValue }
        case .bool(let bool):
            return bool
        case .number(let number):
            return number
        case .string(let string):
            return string
        case .null:
            return NSNull()
        }
    }
    
    var foundationDictionary: [String : AnyObject]? {
        return anyValue as? [String : AnyObject]
    }
    
    var foundationArray: [AnyObject]? {
        return anyValue as? [AnyObject]
    }
}

extension Json {
    public static func from(_ any: AnyObject) -> Json {
        switch any {
            // If we're coming from foundation, it will be an `NSNumber`.
            //This represents double, integer, and boolean.
        case let number as Double:
            return .number(number)
        case let string as String:
            return .string(string)
        case let object as [String : AnyObject]:
            return from(object)
        case let array as [AnyObject]:
            return .array(array.map(from))
        case _ as NSNull:
            return .null
        default:
            fatalError("Unsupported foundation type")
        }
        return .null
    }
    
    public static func from(_ any: [String : AnyObject]) -> Json {
        var mutable: [String : Json] = [:]
        any.forEach { key, val in
            mutable[key] = .from(val)
        }
        return .from(mutable)
    }
}

extension Json {
    public static func deserialize(_ data: NSData) throws -> Json {
        let startPointer = UnsafePointer<UInt8>(data.bytes)
        let bufferPointer = UnsafeBufferPointer(start: startPointer, count: data.length)
        return try deserialize(bufferPointer)
    }
}
