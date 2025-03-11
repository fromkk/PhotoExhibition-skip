import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@MainActor
protocol SettingsStoreDelegate: AnyObject {
  func logoutCompleted()
}

@Observable final class SettingsStore: Store {
  weak var delegate: (any SettingsStoreDelegate)?

  private let currentUserClient: CurrentUserClient
  init(currentUserClient: CurrentUserClient = DefaultCurrentUserClient()) {
    self.currentUserClient = currentUserClient
  }

  enum Action {
    case task
    case logoutButtonTapped
    case presentLogoutConfirmation
  }

  var isErrorAlertPresented: Bool = false
  var error: (any Error)?
  var isLogoutConfirmationPresented: Bool = false

  func send(_ action: Action) {
    switch action {
    case .task:
      break
    case .logoutButtonTapped:
      do {
        try currentUserClient.logout()
        delegate?.logoutCompleted()
      } catch {
        self.error = error
        self.isErrorAlertPresented = true
      }
    case .presentLogoutConfirmation:
      isLogoutConfirmationPresented = true
    }
  }
}

struct SettingsView: View {
  @Bindable var store: SettingsStore
  var body: some View {
    List {
      Button(role: .destructive) {
        store.send(.presentLogoutConfirmation)
      } label: {
        Text("Logout")
      }
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
    .alert(
      "Are you sure you want to log out?",
      isPresented: $store.isLogoutConfirmationPresented,
      actions: {
        Button("Cancel", role: .cancel) {}
        Button("Yes", role: .destructive) {
          store.send(.logoutButtonTapped)
        }
      }
    )
  }
}
