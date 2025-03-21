import SwiftUI

#if !SKIP
  import AuthenticationServices
#endif

struct TopView: View {
  @Bindable var store: RootStore
  @Environment(\.openURL) private var openURL

  var body: some View {
    NavigationStack {
      VStack(spacing: 32) {
        Image("logo", bundle: .module)
          .resizable()
          .aspectRatio(contentMode: .fit)

        #if SKIP
          VStack(spacing: 16) {
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
        #else
          VStack(spacing: 16) {
            SignInWithAppleButton(.signIn) { request in
              request.requestedScopes = [.fullName]
              request.nonce = store.prepareSignInWithApple()
            } onCompletion: { result in
              store.send(.signInWithAppleCompleted(result))
            }
            .frame(height: 44)
          }
        #endif

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
      }
      .padding(16)
      .navigationDestination(isPresented: $store.isSignInScreenShown) {
        if let store = self.store.authStore {
          AuthView(store: store)
        }
      }
      .navigationDestination(isPresented: $store.isSignUpScreenShown) {
        if let store = self.store.authStore {
          AuthView(store: store)
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
    }
  }
}
