import SkipWeb
import SwiftUI

struct TopView: View {
  @Bindable var store: RootStore
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
              store.send(.termsOfServiceButtonTapped)
            } label: {
              Text("Terms of Service")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Button {
              store.send(.privacyPolicyButtonTapped)
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
      .navigationDestination(isPresented: $store.showTermsOfService) {
        WebView(url: Constants.termsOfServiceURL)
      }
      .navigationDestination(isPresented: $store.showPrivacyPolicy) {
        WebView(url: Constants.privacyPolicyURL)
      }
    }
  }
}
