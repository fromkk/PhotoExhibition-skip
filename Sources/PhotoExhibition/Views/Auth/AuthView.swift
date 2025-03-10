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

enum AuthMode: CaseIterable {
  case signIn
  case signUp

  var titleLocalizedKey: LocalizedStringKey {
    switch self {
    case .signIn: return "Sign In"
    case .signUp: return "Sign Up"
    }
  }
}

struct AuthView: View {  // 名前変更: SignInView -> AuthView
  @Bindable var store: AuthStore

  var body: some View {
    VStack {
      if store.authMode == .signIn {
        VStack {
          TextField("Email", text: $store.email)
            .padding()
          SecureField("Password", text: $store.password)
            .padding()
          Button("Sign In") {
            // sign in process
          }
          .padding()
        }
      } else {
        VStack {
          TextField("Email", text: $store.email)
            .padding()
          SecureField("Password", text: $store.password)
            .padding()
          Button("Sign Up") {
            // sign up process
          }
          .padding()
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
