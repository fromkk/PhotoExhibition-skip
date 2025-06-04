# PhotoExhibition

This repository contains a dual-platform application built with [Skip](https://skip.tools). The Swift codebase is transpiled to Kotlin so that the app can run natively on iOS and Android.

## Repository Overview
Swift sources are converted to Kotlin using Skip. The dependencies, including the Skip plugin and Firebase libraries, are defined in `Package.swift`.

### Key Directories
- **Sources/**
  - `PhotoExhibition` – main application module with entry points and views.
  - `PhotoExhibitionModel` – Firebase clients and entity definitions (`Clients/`, `Entities/`).
  - `Viewer` – end-user facing models, clients, and views.
  - `WidgetClients` – clients and entities for widgets.
  - `IntentHelper` – small utilities such as notification name extensions.
- **Tests/**
  - Feature tests under `PhotoExhibitionTests/` and `XCSkipTests.swift` allow Kotlin tests produced by Skip to run.
- **Android/** and **Darwin/**
  - Gradle and Xcode projects generated or consumed by Skip for Android and iOS.

## Important Points
- Conditional compilation (e.g., `#if SKIP`) keeps Swift and Kotlin behavior aligned.
- Firebase integration is central (Firestore, Storage, Auth, etc.); understanding each client clarifies the app's data flow.
- The UI layer relies on `@Observable` store classes, and tests follow the same approach.

## Learning Path for New Contributors
1. **Set up Skip** – Install via Homebrew with `brew install skiptools/skip/skip` and verify prerequisites with `skip checkup`.
2. **Explore Firebase clients** – Inspect `Sources/PhotoExhibitionModel/Clients/` to learn authentication and storage flows.
3. **Study views and stores** – Look at `Sources/PhotoExhibition/Views/` and the `Viewer/` module to see how UI connects to business logic.
4. **Learn the testing style** – Review `Tests/PhotoExhibitionTests/` for mocking and asynchronous test patterns.

## Building
This project works both as a Swift Package Manager module and as an Xcode project that transpiles into an Android Gradle project.

Install Skip via Homebrew:

```bash
brew install skiptools/skip/skip
```

This installation also provides Kotlin, Gradle, and Android build tools. Confirm everything is ready with:

```bash
skip checkup
```

## Testing
Run parity tests across iOS and Android with:

```bash
skip test
```

## Running
Ensure Xcode and Android Studio are installed. Start an Android emulator from Android Studio's Device Manager. Launch the `PhotoExhibitionApp` target from Xcode to build and deploy the Swift and Kotlin apps. iOS logs appear in the Xcode console and Kotlin logs in Android Studio's logcat.
