//
//  ParseError.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

protocol Parser {
    var lineNumber: Int { get }
    var columnNumber: Int { get }
}

open class ParseError: Error, CustomStringConvertible {
    open let reason: String
    let parser: Parser

    open var lineNumber: Int {
        return parser.lineNumber
    }
    open var columnNumber: Int {
        return parser.columnNumber
    }

    open var description: String {
        return "\(Mirror(reflecting: self))[\(lineNumber):\(columnNumber)]: \(reason)"
    }

    init(_ reason: String, _ parser: Parser) {
        self.reason = reason
        self.parser = parser
    }
}

open class UnexpectedTokenError: ParseError { }

open class InsufficientTokenError: ParseError { }

open class ExtraTokenError: ParseError { }

open class NonStringKeyError: ParseError { }

open class InvalidStringError: ParseError { }

open class InvalidNumberError: ParseError { }
