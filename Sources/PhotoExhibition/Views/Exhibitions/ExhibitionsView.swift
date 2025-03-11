import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class ExhibitionsStore: Store {
  let exhibitionsClient: ExhibitionsClient
  init(exhibitionsClient: ExhibitionsClient = DefaultExhibitionsClient()) {
    self.exhibitionsClient = exhibitionsClient
  }

  enum Action {
    case task
  }

  var exhibitions: [Exhibition] = []
  var error: (any Error)?
  var isErrorAlertPresented = false

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        do {
          self.exhibitions = try await exhibitionsClient.fetch()
        } catch {
          print("Error fetching exhibitions: \(error)")
          self.error = error
          self.isErrorAlertPresented = true
        }
      }
    }
  }
}

struct ExhibitionsView: View {
  @Bindable var store: ExhibitionsStore
  var body: some View {
    Text("Exhibitions")
      .task {
        store.send(.task)
      }
      .alert(
        "Error",
        isPresented: $store.isErrorAlertPresented,
        actions: {
          Button("OK") {}
        },
        message: {
          Text(store.error?.localizedDescription ?? "Unknown error")
        }
      )
  }
}
