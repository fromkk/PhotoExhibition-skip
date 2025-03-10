import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class AuthStore: Store {
  enum Action {
    case signInButtonTapped
    case signUpButtonTapped
  }

  var authMode: AuthMode
  var email: String = ""
  var password: String = ""
  var isAuthEnabled: Bool {
    // invalid if email does not contain "@" or password is less than 8 characters
    email.contains("@") && password.count >= 8
  }

  private let signInClient: any SignInClient
  private let signUpClient: any SignUpClient

  init(
    authMode: AuthMode,
    signIngClient: SignInClient = DefaultSignInClient(),
    signUpClient: SignUpClient = DefaultSignUpClient()
  ) {
    self.authMode = authMode
    self.signInClient = signIngClient
    self.signUpClient = signUpClient

    self.email = email
    self.password = password
  }

  func send(_ action: Action) {
    switch action {
    case .signInButtonTapped:
      return
    case .signUpButtonTapped:
      return
    }
  }
}

enum AuthMode: CaseIterable, Hashable {
  case signIn
  case signUp

  var titleLocalizedKey: LocalizedStringKey {
    switch self {
    case .signIn: return "Sign In"
    case .signUp: return "Sign Up"
    }
  }
}

struct AuthView: View {
  @Bindable var store: AuthStore

  var body: some View {
    VStack {
      if store.authMode == .signIn {
        VStack(spacing: 32) {
          VStack(spacing: 16) {
            TextField("Email", text: $store.email)
            SecureField("Password", text: $store.password)
          }

          Button {
            store.send(.signInButtonTapped)
          } label: {
            Text(store.authMode.titleLocalizedKey)
              .primaryButtonStyle()
          }
          .disabled(!store.isAuthEnabled)
        }
      } else {
        VStack(spacing: 32) {
          VStack(spacing: 16) {
            TextField("Email", text: $store.email)
            SecureField("Password", text: $store.password)
          }

          Button {
            store.send(.signUpButtonTapped)
          } label: {
            Text(store.authMode.titleLocalizedKey)
              .primaryButtonStyle()
          }
          .disabled(!store.isAuthEnabled)
        }
      }
    }
    .padding()
    .navigationTitle(Text(store.authMode.titleLocalizedKey))
  }
}

#Preview {
  AuthView(store: AuthStore(authMode: .signIn))
}
