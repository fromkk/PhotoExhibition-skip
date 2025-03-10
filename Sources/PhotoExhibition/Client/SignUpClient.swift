#if SKIP
  import SkipFirebaseAuth
#else
  import FirebaseAuth
#endif

protocol SignUpClient {
  func signUp(email: String, password: String) async throws -> User?
}

class DefaultSignUpClient: SignUpClient {
  func signUp(email: String, password: String) async throws -> User? {
    return try await Auth.auth().createUser(withEmail: email, password: password).user
  }
}
