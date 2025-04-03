import AppIntents
import IntentHelper
import WidgetKit

struct AddExhibitionIntent: AppIntent {
  static let openAppWhenRun: Bool = true
  static let title: LocalizedStringResource = "Add Exhibition"
  func perform() async throws -> some IntentResult {
    NotificationCenter.default.post(name: .addExhibitionRequest, object: nil)
    return .result()
  }
}

extension AddExhibitionIntent: WidgetConfigurationIntent,
  ControlConfigurationIntent
{}
