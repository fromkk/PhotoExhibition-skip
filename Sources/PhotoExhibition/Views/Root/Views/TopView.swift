import SwiftUI

struct TopView: View {
  @Bindable var store: RootStore
  var body: some View {
    NavigationStack {
      VStack {
        // Updated: Sign In button
        Button {
          store.send(.signInButtonTapped)
        } label: {
          Text("Sign In")
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor)
            .foregroundStyle(Color.white)
            .clipShape(Capsule())
        }
        // Updated: Sign Up button
        Button {
          store.send(.signUpButtonTapped)
        } label: {
          Text("Sign Up")
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
            .overlay {
              Capsule()
                .inset(by: 0.5)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.0))
            }
        }
      }
      .navigationDestination(isPresented: $store.isSignInScreenShown) {
        AuthView(store: AuthStore(authMode: .signIn))
      }
      .navigationDestination(isPresented: $store.isSignUpScreenShown) {
        AuthView(store: AuthStore(authMode: .signUp))
      }
    }
  }
}
