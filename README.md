# Swift-JsonSerializer

A pure-Swift JSON serializer and deserializer

# SYNOPSIS

```
import JsonSerializer

let data: NSData

switch JsonParser.parse(data) {
case .Success(let json):
  println(json["foo"]["bar"].stringValue)
case .Error(let error):
  println(error)
}
```

# DESCRIPTION

This is an alpha software. Any API will change.

# KNOWN ISSUES

* This library doesn't work with optimization flags (`swiftc -O`)

# AUTHOR

Fuji, Goro (gfx) gfuji@cpan.org

# LICENSE

The Apache 2.0 License


