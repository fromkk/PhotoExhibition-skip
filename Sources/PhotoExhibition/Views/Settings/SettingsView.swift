import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class SettingsStore: Store {
  enum Action {
    case task
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      break
    }
  }
}

struct SettingsView: View {
  @Bindable var store: SettingsStore
  var body: some View {
    Text("Settings")
  }
}
