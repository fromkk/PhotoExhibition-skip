#if SKIP
  import SkipFirebaseAuth
#else
  import FirebaseAuth
#endif

protocol CurrentUserClient {
  func currentUser() -> User?
  func logout() throws
}

final class DefaultCurrentUserClient: CurrentUserClient {
  func currentUser() -> User? {
    Auth.auth().currentUser
  }

  func logout() throws {
    try Auth.auth().signOut()
  }
}
