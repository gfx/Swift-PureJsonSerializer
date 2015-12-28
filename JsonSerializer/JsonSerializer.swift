//
//  JsonSerializer.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/18.
//  Copyright (c) 2014年 Fuji Goro. All rights reserved.
//


public protocol JsonSerializer {
    func serialize(_: Json) -> String
}

public class DefaultJsonSerializer: JsonSerializer {
    public func serialize(json: Json) -> String {
        switch json {
        case .NullValue:
            return "null"
        case .BooleanValue(let b):
            return b ? "true" : "false"
        case .NumberValue(let n):
            return serializeNumber(n)
        case .StringValue(let s):
            return escapeAsJsonString(s)
        case .ArrayValue(let a):
            return serializeArray(a)
        case .ObjectValue(let o):
            return serializeObject(o)
        }
    }

    func serializeNumber(n: Double) -> String {
        if n == Double(Int64(n)) {
            return Int64(n).description
        } else {
            return n.description
        }
    }

    func serializeArray(a: [Json]) -> String {
        var s = "["
        for var i = 0; i < a.count; i++ {
            s += a[i].serialize(self)
            if i != (a.count - 1) {
                s += ","
            }
        }
        return s + "]"
    }

    func serializeObject(o: [String:Json]) -> String {
        var s = "{"
        var i = 0
        for entry in o {
            s += "\(escapeAsJsonString(entry.0)):\(entry.1.serialize(self))"
            if i++ != (o.count - 1) {
                s += ","
            }
        }

        return s + "}"
    }

}

public class PrettyJsonSerializer: DefaultJsonSerializer {
    var indentLevel = 0

    override public func serializeArray(a: [Json]) -> String {
        var s = "["
        indentLevel++
        for var i = 0; i < a.count; i++ {
            s += "\n"
            s += indent()
            s += a[i].serialize(self)
            if i != (a.count - 1) {
                s += ","
            }
        }
        indentLevel--
        return s + " ]"
    }

    override public func serializeObject(o: [String:Json]) -> String {
        var s = "{"
        indentLevel++
        var i = 0

        var keys = o.keys.array
        keys.sortInPlace()
        for key in keys {
            s += "\n"
            s += indent()
            s += "\(escapeAsJsonString(key)): \(o[key]!.serialize(self))"
            if i++ != (o.count - 1) {
                s += ","
            }
        }
        indentLevel--
        return s + " }"
    }

    func indent() -> String {
        var s = ""
        for var i = 0; i < indentLevel; i++ {
            s += "  "
        }
        return s
    }
}