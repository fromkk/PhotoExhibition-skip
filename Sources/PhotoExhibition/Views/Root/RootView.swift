import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class RootStore: Store {
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

  private(set) var isSignedIn: Bool = false
  // Updated flags for signIn and signUp screen display
  var isSignInScreenShown: Bool = false
  var isSignUpScreenShown: Bool = false

  func send(_ action: Action) {
    switch action {
    case .task:
      isSignedIn = currentUserClient.currentUser() != nil
    case .signInButtonTapped:
      // Set signIn screen flag to true
      isSignInScreenShown = true
      return
    case .signUpButtonTapped:
      // Set signUp screen flag to true
      isSignUpScreenShown = true
      return
    }
  }
}

struct RootView: View {
  @Bindable var store = RootStore()
  var body: some View {
    Group {
      if store.isSignedIn {
        Text("Signed in")
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
