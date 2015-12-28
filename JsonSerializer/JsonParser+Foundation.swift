//
//  JsonSerializer+Foundation.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/15.
//  Copyright (c) 2014 Fuji Goro. All rights reserved.
//

import class Foundation.NSData

struct PointerGeneratorWrapper<T>: GeneratorType {
    typealias Element = T

    let ptr: PointerSequenceWrapper<T>
    var cur: PointerSequenceWrapper<T>.Index

    init(_ ptr: PointerSequenceWrapper<T>) {
        self.ptr = ptr
        self.cur = ptr.startIndex
    }

    mutating func next() -> Element? {
        if cur != ptr.endIndex {
            return ptr[cur]
        } else {
            return nil
        }
    }
}

struct PointerSequenceWrapper<T>: CollectionType {
    typealias Generator = PointerGeneratorWrapper<T>
    typealias Element = T
    typealias Index = Int

    let begin: UnsafePointer<Element>
    let end: UnsafePointer<Element>

    init(_ begin: UnsafePointer<Element>, _ end: UnsafePointer<Element>) {
        self.begin = begin
        self.end = end
    }

    init(_ source: NSData){
        self.begin = unsafeBitCast(source.bytes, UnsafePointer<T>.self)
        self.end = begin.advancedBy(source.length)
    }

    var startIndex: Index {
        return 0
    }

    var endIndex: Index {
        return begin.distanceTo(end)
    }

    subscript (position: Index) -> Generator.Element {
        return begin.advancedBy(position).memory
    }


    func generate() -> Generator {
        return PointerGeneratorWrapper<T>(self)
    }
}

extension JsonParser {
    public static func parse(data: NSData) throws -> Json {
        let source = PointerSequenceWrapper<UInt8>(data)
        let parser = GenJsonParser(source)
        return try parser.parse()
    }
}
