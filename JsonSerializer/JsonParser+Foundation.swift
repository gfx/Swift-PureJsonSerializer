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
        case .ObjectValue(let ob):
            var mapped: [String : AnyObject] = [:]
            ob.forEach { key, val in
                mapped[key] = val.anyValue
            }
            return mapped
        case .ArrayValue(let array):
            return array.map { $0.anyValue }
        case .BooleanValue(let bool):
            return bool
        case .NumberValue(let number):
            return number
        case .StringValue(let string):
            return string
        case .NullValue:
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
    public static func from(any: AnyObject) -> Json {
        switch any {
            // If we're coming from foundation, it will be an `NSNumber`.
            //This represents double, integer, and boolean.
        case let number as Double:
            return .NumberValue(number)
        case let string as String:
            return .StringValue(string)
        case let object as [String : AnyObject]:
            return from(object)
        case let array as [AnyObject]:
            return .ArrayValue(array.map(from))
        case _ as NSNull:
            return .NullValue
        default:
            fatalError("Unsupported foundation type")
        }
        return .NullValue
    }
    
    public static func from(any: [String : AnyObject]) -> Json {
        var mutable: [String : Json] = [:]
        any.forEach { key, val in
            mutable[key] = .from(val)
        }
        return .from(mutable)
    }
}

extension Json {
    public static func deserialize(data: NSData) throws -> Json {
        let startPointer = UnsafePointer<UInt8>(data.bytes)
        let bufferPointer = UnsafeBufferPointer(start: startPointer, count: data.length)
        return try deserialize(bufferPointer)
    }
}
