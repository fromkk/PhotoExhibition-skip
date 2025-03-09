// swift-tools-version: 6.0
// This is a Skip (https://skip.tools) package,
// containing a Swift Package Manager project
// that will use the Skip build plugin to transpile the
// Swift Package, Sources, and Tests into an
// Android Gradle Project with Kotlin sources and JUnit tests.
import PackageDescription

let package = Package(
  name: "photo-exhibition",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .macCatalyst(.v17),
  ],
  products: [
    .library(
      name: "PhotoExhibitionApp", type: .dynamic, targets: ["PhotoExhibition"])
  ],
  dependencies: [
    .package(url: "https://source.skip.tools/skip.git", from: "1.3.2"),
    .package(url: "https://source.skip.tools/skip-ui.git", from: "1.0.0"),
    .package(url: "https://source.skip.tools/skip-firebase.git", from: "0.7.0"),
  ],
  targets: [
    .target(
      name: "PhotoExhibition",
      dependencies: [
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipFirebaseAuth", package: "skip-firebase"),
      ],
      resources: [.process("Resources")],
      plugins: [.plugin(name: "skipstone", package: "skip")]),
    .testTarget(
      name: "PhotoExhibitionTests",
      dependencies: [
        "PhotoExhibition",
        .product(name: "SkipTest", package: "skip"),
      ],
      resources: [.process("Resources")],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
  ]
)
