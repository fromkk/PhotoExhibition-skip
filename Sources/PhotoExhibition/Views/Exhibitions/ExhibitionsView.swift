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

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        self.exhibitions = try await exhibitionsClient.fetch()
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
  }
}
