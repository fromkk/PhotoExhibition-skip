import SwiftUI

#if !SKIP
  import AuthenticationServices
#endif

struct AuthRootView: View {
  @Bindable var store: AuthRootStore
  @Environment(\.openURL) private var openURL

  init(delegate: any AuthRootStoreDelegate) {
    self.store = AuthRootStore()
    self.store.delegate = delegate
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 32) {
        Image("logo", bundle: .module)
          .resizable()
          .aspectRatio(contentMode: .fit)

        VStack(spacing: 16) {
          #if !SKIP
            SignInWithAppleButton(.signIn) { request in
              request.requestedScopes = [.fullName]
              request.nonce = store.prepareSignInWithApple()
            } onCompletion: { result in
              store.send(.signInWithAppleCompleted(result))
            }
            .frame(height: 44)
          #endif

          Button {
            store.send(.signInButtonTapped)
          } label: {
            Text("Sign In")
              .primaryButtonStyle()
          }
          Button {
            store.send(.signUpButtonTapped)
          } label: {
            Text("Sign Up")
              .secondaryButtonStyle()
          }
        }

        HStack(spacing: 16) {
          Button {
            openURL(Constants.termsOfServiceURL)
          } label: {
            Text("Terms of Service")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }

          Button {
            openURL(Constants.privacyPolicyURL)
          } label: {
            Text("Privacy Policy")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.top, 8)

        if let version = store.deviceInfo.appVersion,
          let buildNumber = store.deviceInfo.buildNumber
        {
          Text("\(version) (\(buildNumber))")
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .center)
        }
      }
      .padding(16)
      .navigationDestination(isPresented: $store.showSignIn) {
        if let authStore = store.authStore {
          AuthView(store: authStore)
        }
      }
      .navigationDestination(isPresented: $store.showSignUp) {
        if let authStore = store.authStore {
          AuthView(store: authStore)
        }
      }
      .alert(
        "Error",
        isPresented: .init(
          get: { store.error != nil },
          set: { if !$0 { store.error = nil } }
        )
      ) {
        Button("OK") {
          store.error = nil
        }
      } message: {
        if let error = store.error {
          Text(error.localizedDescription)
        }
      }
      .task {
        store.send(.task)
      }
    }
  }
}

#Preview {
  NavigationStack {
    AuthRootView(delegate: PreviewAuthRootStoreDelegate())
  }
}

private final class PreviewAuthRootStoreDelegate: AuthRootStoreDelegate {
  func didSignInSuccessfully(with member: Member) {
    print("didSignInSuccessfully: \(member)")
  }
}
