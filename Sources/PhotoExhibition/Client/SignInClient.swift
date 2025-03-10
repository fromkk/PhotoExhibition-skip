#if SKIP
  import SkipFirebaseAuth
#else
  import FirebaseAuth
#endif

protocol SignInClient {
  func signIn(email: String, password: String) async throws -> User?
}

class DefaultSignInClient: SignInClient {
  func signIn(email: String, password: String) async throws -> User? {
    return try await Auth.auth().signIn(withEmail: email, password: password).user
  }
}
