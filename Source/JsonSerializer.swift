//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/18.
//  Copyright (c) 2014年 Fuji Goro. All rights reserved.
//

public protocol JsonSerializer {
    init()
    func serialize(_: Json) -> String
}

internal class DefaultJsonSerializer: JsonSerializer {
    
    required init() {}
    
    internal func serialize(_ json: Json) -> String {
        switch json {
        case .nullValue:
            return "null"
        case .booleanValue(let b):
            return b ? "true" : "false"
        case .numberValue(let n):
            return serializeNumber(n)
        case .StringValue(let s):
            return escapeAsJsonString(s)
        case .ArrayValue(let a):
            return serializeArray(a)
        case .ObjectValue(let o):
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

    func serializeArray(_ array: [Json]) -> String {
        var string = "["
        string += array
            .map { $0.serialize(self) }
            .joined(separator: ",")
        return string + "]"
    }

    func serializeObject(_ object: [String : Json]) -> String {
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
    fileprivate var indentLevel = 0

    required init() {
        super.init()
    }
    
    override internal func serializeArray(_ array: [Json]) -> String {
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

    override internal func serializeObject(_ object: [String : Json]) -> String {
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
