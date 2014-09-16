//
//  StringUtils.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import Foundation


let unescapeMapping: [UnicodeScalar: UnicodeScalar] = [
    "t": "\t",
    "r": "\r",
    "n": "\n",
]


let escapeMapping: [Character: String] = [
    "\r": "\\r",
    "\n": "\\n",
    "\t": "\\t",
    "\\": "\\\\",
    "\"": "\\\"",

    "\u{2028}": "\\u2028", // LINE SEPARATOR
    "\u{2029}": "\\u2029", // PARAGRAPH SEPARATOR

    // XXX: countElements("\r\n") is 1 in Swift 1.0
    "\r\n": "\\r\\n",
]

let hexMapping: [Byte:UInt32] = [
    Byte("0"): 0x0,
    Byte("1"): 0x1,
    Byte("2"): 0x2,
    Byte("3"): 0x3,
    Byte("4"): 0x4,
    Byte("5"): 0x5,
    Byte("6"): 0x6,
    Byte("7"): 0x7,
    Byte("8"): 0x8,
    Byte("9"): 0x9,
    Byte("a"): 0xA, Byte("A"): 0xA,
    Byte("b"): 0xB, Byte("B"): 0xB,
    Byte("c"): 0xC, Byte("C"): 0xC,
    Byte("d"): 0xD, Byte("D"): 0xD,
    Byte("e"): 0xE, Byte("E"): 0xE,
    Byte("f"): 0xF, Byte("F"): 0xF,
]

public func escapeAsJsonString(source : String) -> String {
    var s = "\""
    s.reserveCapacity(source.utf16Count * 2)

    for c in source {
        if let escapedSymbol = escapeMapping[c] {
            s.extend(escapedSymbol)
        } else {
            s.append(c)
        }
    }
    s.extend("\"")
    return s
}


func hexToDigit(b: Byte) -> UInt32? {
    return hexMapping[b]
}

