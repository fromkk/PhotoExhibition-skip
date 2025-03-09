#if SKIP
  import SkipFirebaseAuth
#else
  import FirebaseAuth
#endif

protocol CurrentUserClient {
  func currentUser() -> User?
}

final class DefaultCurrentUserClient: CurrentUserClient {
  func currentUser() -> User? {
    Auth.auth().currentUser
  }
}
