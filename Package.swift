import PackageDescription

let package = Package(
    name: "PureJSON",
    dependencies: [
      .Package(url: "https://github.com/qutheory/path-indexable.git", majorVersion: 0, minor: 1),
      .Package(url: "https://github.com/open-swift/C7.git", majorVersion: 0, minor: 8)
    ],
    targets: [
        Target(
            name: "PureJSON"
        ),
        Target(
            name: "PureJSONFoundation",
            dependencies: [
                .Target(name: "PureJSON")
            ]
        )
    ]
)
