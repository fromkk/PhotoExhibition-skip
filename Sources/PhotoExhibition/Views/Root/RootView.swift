import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class RootStore: Store, AuthStoreDelegate {
  private let currentUserClient: CurrentUserClient

  init(
    currentUserClient: CurrentUserClient = DefaultCurrentUserClient()
  ) {
    self.currentUserClient = currentUserClient
  }

  enum Action: Sendable {
    case task
    case signInButtonTapped
    case signUpButtonTapped
  }

  private(set) var isSignedIn: Bool = false {
    didSet {
      if isSignedIn {
        exhibitionsStore = ExhibitionsStore()
        settingsStore = SettingsStore()
      } else {
        exhibitionsStore = nil
        settingsStore = nil
      }
    }
  }
  // Updated flags for signIn and signUp screen display
  var isSignInScreenShown: Bool = false {
    didSet {
      if isSignInScreenShown {
        authStore = AuthStore(authMode: .signIn)
        authStore?.delegate = self
      } else {
        authStore = nil
      }
    }
  }
  var isSignUpScreenShown: Bool = false {
    didSet {
      if isSignUpScreenShown {
        authStore = AuthStore(authMode: .signUp)
        authStore?.delegate = self
      } else {
        authStore = nil
      }
    }
  }

  private(set) var authStore: AuthStore?
  private(set) var exhibitionsStore: ExhibitionsStore?
  private(set) var settingsStore: SettingsStore?

  func send(_ action: Action) {
    switch action {
    case .task:
      isSignedIn = currentUserClient.currentUser() != nil
    case .signInButtonTapped:
      isSignInScreenShown = true
      return
    case .signUpButtonTapped:
      isSignUpScreenShown = true
      return
    }
  }

  func didSignInSuccessfully() {
    isSignedIn = true
  }
}

struct RootView: View {
  @Bindable var store = RootStore()
  var body: some View {
    Group {
      if store.isSignedIn {
        TabView {
          if let store = store.exhibitionsStore {
            ExhibitionsView(store: store)
              .tabItem {
                Label("Exhibitions", systemImage: "photo")
              }
          }

          if let store = store.settingsStore {
            SettingsView(store: store)
              .tabItem {
                Label("Settings", systemImage: "gear")
              }
          }
        }
      } else {
        TopView(store: store)
      }
    }
    .background(Color("background"))
    .task {
      store.send(.task)
    }
  }
}

#Preview {
  RootView()
}
