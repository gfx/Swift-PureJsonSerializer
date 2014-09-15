//
//  JsonSerializer+Foundation.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import Foundation

extension JsonParser {
    public class func parse(source: NSData) -> Result {
        let begin = unsafeBitCast(source.bytes, UnsafePointer<Byte>.self)
        let end = begin.advancedBy(source.length)
        return JsonParser(source, begin, end).parseValue()
    }
}
