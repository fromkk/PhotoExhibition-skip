import FirebaseCore
import PhotoExhibition
import SwiftUI

/// The entry point to the app simply loads the App implementation from SPM module.
@main struct AppMain: App {
  @AppDelegateAdaptor(AppMainDelegate.self) var appDelegate
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      PhotoExhibitionRootView()
    }
    .onChange(of: scenePhase) { oldPhase, newPhase in
      switch newPhase {
      case .active:
        AppDelegate.shared.onResume(appDelegate.application)
      case .inactive:
        AppDelegate.shared.onPause(appDelegate.application)
      case .background:
        AppDelegate.shared.onStop(appDelegate.application)
      @unknown default:
        print("unknown app phase: \(newPhase)")
      }
    }
  }
}

typealias AppDelegate = PhotoExhibitionAppDelegate
#if canImport(UIKit)
  typealias AppDelegateAdaptor = UIApplicationDelegateAdaptor
  typealias AppMainDelegateBase = UIApplicationDelegate
  typealias AppType = UIApplication
#elseif canImport(AppKit)
  typealias AppDelegateAdaptor = NSApplicationDelegateAdaptor
  typealias AppMainDelegateBase = NSApplicationDelegate
  typealias AppType = NSApplication
#endif

class AppMainDelegate: NSObject, AppMainDelegateBase {
  let application = AppType.shared

  #if canImport(UIKit)
    func application(
      _ application: UIApplication,
      willFinishLaunchingWithOptions launchOptions: [UIApplication
        .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
      AppDelegate.shared.onStart(application)
      FirebaseApp.configure()
      return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
      AppDelegate.shared.onDestroy(application)
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
      AppDelegate.shared.onLowMemory(application)
    }
  #elseif canImport(AppKit)
    func applicationWillFinishLaunching(_ notification: Notification) {
      AppDelegate.shared.onStart(application)
      FirebaseApp.configure()
    }

    func applicationWillTerminate(_ application: Notification) {
      AppDelegate.shared.onDestroy(application)
    }
  #endif

}
