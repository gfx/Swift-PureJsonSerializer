//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/18.
//  Copyright (c) 2014年 Fuji Goro. All rights reserved.
//

public protocol JsonSerializer {
    init()
    func serialize(_: JSON) -> String
}

internal class DefaultJsonSerializer: JsonSerializer {
    
    required init() {}
    
    internal func serialize(_ json: JSON) -> String {
        switch json {
        case .null:
            return "null"
        case .bool(let b):
            return b ? "true" : "false"
        case .number(let n):
            return serializeNumber(n)
        case .string(let s):
            return escapeAsJsonString(s)
        case .array(let a):
            return serializeArray(a)
        case .object(let o):
            return serializeObject(o)
        }
    }

    func serializeNumber(_ n: Double) -> String {
        if n == Double(Int64(n)) {
            return Int64(n).description
        } else {
            return n.description
        }
    }

    func serializeArray(_ array: [JSON]) -> String {
        var string = "["
        string += array
            .map { $0.serialize(self) }
            .joined(separator: ",")
        return string + "]"
    }

    func serializeObject(_ object: [String : JSON]) -> String {
        var string = "{"
        string += object
            .map { key, val in
                let escapedKey = escapeAsJsonString(key)
                let serializedVal = val.serialize(self)
                return "\(escapedKey):\(serializedVal)"
            }
            .joined(separator: ",")
        return string + "}"
    }

}

internal class PrettyJsonSerializer: DefaultJsonSerializer {
    private var indentLevel = 0

    required init() {
        super.init()
    }
    
    override internal func serializeArray(_ array: [JSON]) -> String {
        indentLevel += 1
        defer {
            indentLevel -= 1
        }
        
        let indentString = indent()
        
        var string = "[\n"
        string += array
            .map { val in
                let serialized = val.serialize(self)
                return indentString + serialized
            }
            .joined(separator: ",\n")
        return string + " ]"
    }

    override internal func serializeObject(_ object: [String : JSON]) -> String {
        indentLevel += 1
        defer {
            indentLevel -= 1
        }
        
        let indentString = indent()
        
        var string = "{\n"
        string += object
            .map { key, val in
                let escapedKey = escapeAsJsonString(key)
                let serializedValue = val.serialize(self)
                let serializedLine = "\(escapedKey): \(serializedValue)"
                return indentString + serializedLine
            }
            .joined(separator: ",\n")
        string += " }"
        
        return string
    }

    func indent() -> String {
        return Array(1...indentLevel)
            .map { _ in "  " }
            .joined(separator: "")
    }
}
