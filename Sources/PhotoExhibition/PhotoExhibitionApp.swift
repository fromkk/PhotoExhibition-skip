import Foundation
import OSLog
import SwiftUI

#if !os(Android)
  import GoogleMobileAds
#endif

private let logger: Logger = Logger(
  subsystem: "me.fromkk.PhotoExhibition", category: "PhotoExhibition")

/// The Android SDK number we are running against, or `nil` if not running on Android
let androidSDK = ProcessInfo.processInfo.environment[
  "android.os.Build.VERSION.SDK_INT"
].flatMap({ Int($0) })

/// The shared top-level view for the app, loaded from the platform-specific App delegates below.
///
/// The default implementation merely loads the `ContentView` for the app and logs a message.
public struct PhotoExhibitionRootView: View {
  @ObservedObject var appDelegate = PhotoExhibitionAppDelegate.shared

  public init() {
    #if !os(Android)
      MobileAds.shared.start(completionHandler: nil)
    #endif
  }

  public var body: some View {
    RootView()
      .task {
        logger.info(
          "Welcome to Skip on \(androidSDK != nil ? "Android" : "Darwin")!")
        logger.info(
          "Skip app logs are viewable in the Xcode console for iOS; Android logs can be viewed in Studio or using adb logcat"
        )
      }
  }
}

/// Global application delegate functions.
///
/// This functions can update a shared observable object to communicate app state changes to interested views.
/// The sender for each of these functions will be either a `UIApplication` (iOS) or `AppCompatActivity` (Android)
public final class PhotoExhibitionAppDelegate: ObservableObject, Sendable {
  public static let shared = PhotoExhibitionAppDelegate()

  private init() {
  }

  public func onStart(_ sender: Any) {
    logger.debug("onStart")
  }

  public func onResume(_ sender: Any) {
    logger.debug("onResume")
  }

  public func onPause(_ sender: Any) {
    logger.debug("onPause")
  }

  public func onStop(_ sender: Any) {
    logger.debug("onStop")
  }

  public func onDestroy(_ sender: Any) {
    logger.debug("onDestroy")
  }

  public func onLowMemory(_ sender: Any) {
    logger.debug("onLowMemory")
  }
}
