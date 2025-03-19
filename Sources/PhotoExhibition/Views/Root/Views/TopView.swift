import SkipWeb
import SwiftUI

struct TopView: View {
  @Bindable var store: RootStore
  @Environment(\.openURL) private var openURL

  var body: some View {
    NavigationStack {
      VStack(spacing: 32) {
        Image("logo", bundle: .module)
          .resizable()
          .aspectRatio(contentMode: .fit)

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

          HStack(spacing: 16) {
            Button {
              #if SKIP && os(iOS)
                openURL(Constants.termsOfServiceURL)
              #else
                store.send(.termsOfServiceButtonTapped)
              #endif
            } label: {
              Text("Terms of Service")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Button {
              #if SKIP && os(iOS)
                openURL(Constants.privacyPolicyURL)
              #else
                store.send(.privacyPolicyButtonTapped)
              #endif
            } label: {
              Text("Privacy Policy")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.top, 8)
        }
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
      #if !SKIP && os(iOS)
        .navigationDestination(isPresented: $store.showTermsOfService) {
          WebView(url: Constants.termsOfServiceURL)
        }
        .navigationDestination(isPresented: $store.showPrivacyPolicy) {
          WebView(url: Constants.privacyPolicyURL)
        }
      #endif
    }
  }
}
