import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 18.0, *)
struct AddExhibitionControlWidget: ControlWidget {
  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(
      kind: "AddExhibitionWidget",
      intent: AddExhibitionIntent.self
    ) { configuration in
      ControlWidgetButton(action: configuration) {
        Image(systemName: "plus")
        Text("Add Exhibition")
      }
    }
  }
}
