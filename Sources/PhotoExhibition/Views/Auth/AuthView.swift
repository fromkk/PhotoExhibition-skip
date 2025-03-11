import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@MainActor
protocol AuthStoreDelegate: AnyObject {
  func didSignInSuccessfully()
}

@Observable final class AuthStore: Store {
  enum Action {
    case signInButtonTapped
    case signUpButtonTapped
    case dismissError
  }

  var authMode: AuthMode
  var email: String = ""
  var password: String = ""
  var isAuthEnabled: Bool {
    // invalid if email does not contain "@" or password is less than 8 characters
    email.contains("@") && password.count >= 8
  }
  weak var delegate: (any AuthStoreDelegate)?

  private let signInClient: any SignInClient
  private let signUpClient: any SignUpClient

  // ユーザー認証状態を管理するプロパティ
  var isLoading: Bool = false
  var error: (any Error)?
  var isErrorAlertPresented: Bool = false

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
      Task {
        isLoading = true
        error = nil
        isErrorAlertPresented = false

        do {
          let member = try await signInClient.signIn(email: email, password: password)
          print("サインイン成功: \(String(describing: member.id))")
          delegate?.didSignInSuccessfully()
        } catch {
          self.error = error
          self.isErrorAlertPresented = true
          print("サインインエラー: \(error.localizedDescription)")
        }

        isLoading = false
      }

    case .signUpButtonTapped:
      Task {
        isLoading = true
        error = nil
        isErrorAlertPresented = false

        do {
          let member = try await signUpClient.signUp(email: email, password: password)
          print("サインアップ成功: \(String(describing: member.id))")
          delegate?.didSignInSuccessfully()
        } catch {
          self.error = error
          self.isErrorAlertPresented = true
          print("サインアップエラー: \(error.localizedDescription)")
        }

        isLoading = false
      }

    case .dismissError:
      isErrorAlertPresented = false
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
    VStack(spacing: 32) {
      VStack(spacing: 16) {
        TextField("Email", text: $store.email)
          .keyboardType(.emailAddress)
          #if !SKIP
            .autocapitalization(.none)
            .disableAutocorrection(true)
          #endif
        SecureField("Password", text: $store.password)
      }

      Button {
        if store.authMode == .signIn {
          store.send(.signInButtonTapped)
        } else {
          store.send(.signUpButtonTapped)
        }
      } label: {
        if store.isLoading {
          ProgressView()
        } else {
          Text(store.authMode.titleLocalizedKey)
            .primaryButtonStyle()
        }
      }
      .disabled(!store.isAuthEnabled || store.isLoading)
    }
    .padding()
    .navigationTitle(Text(store.authMode.titleLocalizedKey))
    .alert(
      "Error",
      isPresented: $store.isErrorAlertPresented,
      actions: {
        Button {
          store.send(.dismissError)
        } label: {
          Text("OK")
        }
      },
      message: {
        Text(store.error?.localizedDescription ?? "An unknown error occurred")
      }
    )
  }
}

#Preview {
  AuthView(store: AuthStore(authMode: .signIn))
}
