import PackageDescription

let package = Package(
    name: "PureJSON",
    dependencies: [
      .Package(url: "https://github.com/qutheory/path-indexable.git", majorVersion: 0, minor: 1)
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
