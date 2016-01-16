# PureJsonSerializer [![Build Status](https://travis-ci.org/gfx/Swift-PureJsonSerializer.svg)](https://travis-ci.org/gfx/Swift-PureJsonSerializer)

A pure-Swift JSON serializer and deserializer.

# COCOAPODS

Lot's of CocoaPods means lots of failed namespaces. The actual pod for this library is called `PureJsonSerializer`.

```Ruby
pod 'PureJsonSerializer'
```

# DESERIALIZE

```Swift
import PureJsonSerializer

// parse a JSON data
let data: NSData = ...

do {
  let json = try Json.deserialize(jsonSource)
  let value = json["Foo"]?["bar"]?.stringValue ?? ""
  print(value)
} catch {
  print("Json serialization failed with error: \(error)")
}
```

# BUILD

```Swift
// build a JSON structure
let profile: Json = [
  "name": "Swift",
  "started": 2014,
  "keywords": ["OOP", "functional programming", "static types", "iOS"],
]
println(profile.description)      // packed JSON string
println(profile.debugDescription) // pretty JSON string
```

# SERIALIZE

```Swift
let serializedJson = json.serialize(.PrettyPrint)
```

# DESCRIPTION

Swift-JsonSerializer is a JSON serializer and deserializer which are implemented in **Pure Swift** and adds nothing
to built-in / standard classes in Swift.

# GENOME

This library is featured in a complete Json mapping library you can find <a href="https://github.com/LoganWright/Genome">here.</a>

# KNOWN ISSUES

* This library doesn't work with optimization flags (`swiftc -O`) as of Xcode 6.1.1 / Swift version 1.1 (swift-600.0.56.1).

# SEE ALSO

* [RFC 7159  The JavaScript Object Notation (JSON) Data Interchange Format](http://tools.ietf.org/html/rfc7159)

# AUTHOR

Fuji, Goro (gfx) gfuji@cpan.org

# LICENSE

The Apache 2.0 License
