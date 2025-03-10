import SwiftUI

struct TopView: View {
  @Bindable var store: RootStore
  var body: some View {
    NavigationStack {
      VStack {
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
    }
  }
}
