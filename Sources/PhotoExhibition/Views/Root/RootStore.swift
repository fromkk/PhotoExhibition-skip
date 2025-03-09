import Foundation
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class RootStore: Store {
  private let currentUserClient: CurrentUserClient

  init(currentUserClient: CurrentUserClient = DefaultCurrentUserClient()) {
    self.currentUserClient = currentUserClient
  }

  enum Action: Sendable {
    case task
  }

  private(set) var isSignedIn: Bool = false

  func send(_ action: Action) {
    switch action {
    case .task:
      isSignedIn = currentUserClient.currentUser() != nil
    }
  }
}
