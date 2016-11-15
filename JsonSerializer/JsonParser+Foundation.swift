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
            return mapped as AnyObject
        case .ArrayValue(let array):
            return array.map { $0.anyValue } as AnyObject
        case .booleanValue(let bool):
            return bool as AnyObject
        case .numberValue(let number):
            return number as AnyObject
        case .StringValue(let string):
            return string as AnyObject
        case .nullValue:
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
            return .numberValue(number)
        case let string as String:
            return .StringValue(string)
        case let object as [String : AnyObject]:
            return from(object)
        case let array as [AnyObject]:
            return .ArrayValue(array.map(from))
        case _ as NSNull:
            return .nullValue
        default:
            fatalError("Unsupported foundation type")
        }
        return .nullValue
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
    public static func deserialize(_ data: Data) throws -> Json {
        let startPointer = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
        let bufferPointer = UnsafeBufferPointer(start: startPointer, count: data.count)
        return try deserialize(bufferPointer)
    }
}
