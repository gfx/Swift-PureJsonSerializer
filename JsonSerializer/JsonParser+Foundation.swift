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
            return mapped as AnyObject
        case .array(let array):
            return array.map { $0.anyValue }  as AnyObject
        case .bool(let bool):
            return bool as AnyObject
        case .number(let number):
            return number as AnyObject
        case .string(let string):
            return string as AnyObject
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
    public init(_ any: AnyObject) {
        switch any {
            // If we're coming from foundation, it will be an `NSNumber`.
            //This represents double, integer, and boolean.
        case let number as Double:
            self = .number(number)
        case let string as String:
            self = .string(string)
        case let object as [String : AnyObject]:
            self = Json(object)
        case let array as [AnyObject]:
            self = .array(array.map(Json.init))
        case _ as NSNull:
            self = .null
        default:
            fatalError("Unsupported foundation type")
        }
    }
    
    public init(_ any: [String : AnyObject]) {
        var mutable: [String : Json] = [:]
        any.forEach { key, val in
            mutable[key] = Json(val)
        }
        self = Json(mutable)
    }
}

extension Json {
    public static func deserialize(_ data: NSData) throws -> Json {
        let startPointer = UnsafePointer<UInt8>(data.bytes)
        let bufferPointer = UnsafeBufferPointer(start: startPointer, count: data.length)
        return try deserialize(bufferPointer)
    }
}
