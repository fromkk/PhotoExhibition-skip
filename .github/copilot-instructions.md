# About

- This project is developing a mobile application using Skip (a library that enables creating iOS/Android apps).
- It is a mobile app named Exhivision that allows anyone to host photo exhibitions.

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

## Coding

- The available SwiftUI features are limited when using Skip.
- Please refer to https://github.com/skiptools/skip-ui as needed.

## Code Review Guidelines

### Architecture
- Ensure proper separation of concerns between `PhotoExhibition`, `PhotoExhibitionModel`, and `Viewer` modules.
- Keep Firebase-related logic in `PhotoExhibitionModel/Clients/`.
- Widget-specific code should be isolated in `WidgetClients/`.

### Skip Compatibility
- Verify that SwiftUI features used are supported by Skip.
- Check that Android-specific behavior is properly handled.
- Test on both iOS and Android platforms when modifying shared code.

### Code Quality
- Follow Swift naming conventions and style guidelines.
- Add appropriate documentation comments for public APIs.
- Keep view files focused and extract reusable components when appropriate.
- Ensure proper error handling, especially in Firebase client code.

## Response

- Please respond in Japanese.
