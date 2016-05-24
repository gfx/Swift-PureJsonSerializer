import PackageDescription

let package = Package(
    name: "PureJson",
    dependencies: [
      .Package(url: "https://github.com/qutheory/path-indexable.git", majorVersion: 0, minor: 1)
    ]
)
