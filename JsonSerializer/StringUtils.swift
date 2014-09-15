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

// TODO: consider Unicode escape sequence
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

