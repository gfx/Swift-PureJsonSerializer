//
//  JsonSerializer+Foundation.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import var Foundation.NSUTF8StringEncoding
import class Foundation.NSData

extension JsonParser {
    public class func parse(source: String) -> Result {
        let data = source.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        return JsonParser.parse(data)
    }

    public class func parse(source: NSData) -> Result {
        let begin = unsafeBitCast(source.bytes, UnsafePointer<UInt8>.self)
        let end = begin.advancedBy(source.length)
        return JsonParser(begin, end).parse()
    }
}
