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
    .iOS(.v17)
  ],
  products: [
    .library(
      name: "PhotoExhibitionApp", type: .dynamic, targets: ["PhotoExhibition"])
  ],
  dependencies: [
    .package(url: "https://source.skip.tools/skip.git", from: "1.3.4"),
    .package(url: "https://source.skip.tools/skip-ui.git", from: "1.26.7"),
    .package(url: "https://source.skip.tools/skip-kit.git", from: "0.3.1"),
    .package(url: "https://source.skip.tools/skip-firebase.git", from: "0.7.3"),
  ],
  targets: [
    .target(
      name: "PhotoExhibition",
      dependencies: [
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipKit", package: "skip-kit"),
        .product(name: "SkipFirebaseAnalytics", package: "skip-firebase"),
        .product(name: "SkipFirebaseAuth", package: "skip-firebase"),
        .product(name: "SkipFirebaseCrashlytics", package: "skip-firebase"),
        .product(name: "SkipFirebaseFirestore", package: "skip-firebase"),
        .product(name: "SkipFirebaseFunctions", package: "skip-firebase"),
        .product(name: "SkipFirebaseStorage", package: "skip-firebase"),
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
