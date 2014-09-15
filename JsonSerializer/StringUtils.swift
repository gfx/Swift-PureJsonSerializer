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

    // XXX: Swift's issue? countElements("\r\n") is 1
    "\r\n": "\\r\\n",

    // for security reasons
    // cf. https://metacpan.org/source/KAZEBURO/JavaScript-Value-Escape-0.06/lib/JavaScript/Value/Escape.pm
    "\\": "\\u005c",
    "\"": "\\u0022",
    "\'": "\\u0027",
    "<": "\\u003c",
    ">": "\\u003e",
    "&": "\\u0026",
    "=": "\\u003d",
    "-": "\\u002d",
    ";": "\\u003b",
    "+": "\\u002b",
    "\u{2028}": "\\u2028",
    "\u{2029}": "\\u2029",
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

