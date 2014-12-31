# Swift-JsonSerializer [![Build Status](https://travis-ci.org/gfx/Swift-JsonSerializer.svg)](https://travis-ci.org/gfx/Swift-JsonSerializer)

A pure-Swift JSON parser and serializer

# SYNOPSIS

```
import class JsonSerializer.JsonParser
import enum JsonSerializer.Json

// parse a JSON data
let data: NSData

switch JsonParser.parse(data) {
case .Success(let json):
  println(json["foo"]["bar"].stringValue)
case .Error(let error):
  println(error)
}

// build a JSON structure
let profile: Json = [
  "name": "Swift",
  "started": 2014,
  "keywords": ["OOP", "functional programming", "static types", "iOS"],
]
println(profile.description)      // packed JSON string
println(profile.debugDescription) // pretty JSON string
```

# DESCRIPTION

Swift-JsonSerializer is a JSON serializer and deserializer which are implemented in **pure Swift** and adds nothing
to built-in / standard classes in Swift.

# KNOWN ISSUES

* This library doesn't work with optimization flags (`swiftc -O`) as of Xcode 6.1.1 / Swift version 1.1 (swift-600.0.56.1).

# SEE ALSO

* [RFC 7159  The JavaScript Object Notation (JSON) Data Interchange Format](http://tools.ietf.org/html/rfc7159)

# AUTHOR

Fuji, Goro (gfx) gfuji@cpan.org

# LICENSE

The Apache 2.0 License
