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

let escapeMapping: [Character: Character] = [
    "\t": "t",
    "\r": "r",
    "\n": "n",
    "\\": "\\",
    "\"": "\"",
]

// TODO: consider Unicode escape sequence
public func escapeAsJsonString(source : String) -> String {
    var s = "\""

    for c in source {
        if let escapedSymbol = escapeMapping[c] {
            s.append(Character("\\"))
            s.append(escapedSymbol)
        } else {
            s.append(c)
        }
    }

    return s + "\""
}

