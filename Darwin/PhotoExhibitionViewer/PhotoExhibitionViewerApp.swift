import FirebaseCore
import SwiftUI

@main
struct PhotoExhibitionViewerApp: App {
  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
