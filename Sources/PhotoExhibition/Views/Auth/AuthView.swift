import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@MainActor
protocol AuthStoreDelegate: AnyObject {
  func didSignInSuccessfully(with member: Member)
}

@Observable final class AuthStore: Store {
  enum Action {
    case task
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
  private let analyticsClient: any AnalyticsClient

  // ユーザー認証状態を管理するプロパティ
  var isLoading: Bool = false
  var error: (any Error)?
  var isErrorAlertPresented: Bool = false

  init(
    authMode: AuthMode,
    signIngClient: any SignInClient = DefaultSignInClient(),
    signUpClient: any SignUpClient = DefaultSignUpClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.authMode = authMode
    self.signInClient = signIngClient
    self.signUpClient = signUpClient
    self.analyticsClient = analyticsClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        await analyticsClient.analyticsScreen(name: "AuthView")
      }
    case .signInButtonTapped:
      isLoading = true
      error = nil
      isErrorAlertPresented = false
      Task {
        do {
          let member = try await signInClient.signIn(email: email, password: password)
          print("サインイン成功: \(String(describing: member.id))")
          await analyticsClient.send(.signIn, parameters: [:])
          delegate?.didSignInSuccessfully(with: member)
        } catch {
          self.error = error
          self.isErrorAlertPresented = true
          print("サインインエラー: \(error.localizedDescription)")
        }

        isLoading = false
      }

    case .signUpButtonTapped:
      isLoading = true
      error = nil
      isErrorAlertPresented = false
      Task {
        do {
          let member = try await signUpClient.signUp(email: email, password: password)
          print("サインアップ成功: \(String(describing: member.id))")
          await analyticsClient.send(.signUp, parameters: [:])
          delegate?.didSignInSuccessfully(with: member)
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
          #if os(iOS)
            .keyboardType(.emailAddress)
          #endif
          #if !SKIP && os(iOS)
            .autocapitalization(.none)
            .disableAutocorrection(true)
          #endif
          #if os(iOS)
            .textFieldStyle(.roundedBorder)
          #endif

        SecureField("Password", text: $store.password)
          .textFieldStyle(.roundedBorder)
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
    .task {
      store.send(.task)
    }
  }
}

#Preview {
  AuthView(store: AuthStore(authMode: .signIn))
}
