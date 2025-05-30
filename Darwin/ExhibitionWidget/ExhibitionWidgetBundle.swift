import FirebaseCore
import SwiftUI
import WidgetKit

@main
struct ExhibitionWidgetBundle: WidgetBundle {
  init() {
    FirebaseApp.configure()
  }

  var body: some Widget {
    ExhibitionWidget()
    AddExhibitionLockScreenWidget()
    if #available(iOS 18.0, *) {
      AddExhibitionControlWidget()
    }
  }
}
