#if SKIP
  import SkipFirebaseAuth
#else
  import FirebaseAuth
#endif

protocol UserProtocol: AnyObject {
  var uid: String { get }
}

#if !SKIP
  extension User: UserProtocol {}
#endif

protocol CurrentUserClient {
  func currentUser() -> (any UserProtocol)?
  func logout() throws
}

final class DefaultCurrentUserClient: CurrentUserClient {
  func currentUser() -> (any UserProtocol)? {
    Auth.auth().currentUser
  }

  func logout() throws {
    try Auth.auth().signOut()
  }
}
