#if SKIP
  import SkipFirebaseAuth
#else
  import FirebaseAuth
#endif

public struct User: Hashable {
  public let uid: String

  public init(uid: String) {
    self.uid = uid
  }
}

public protocol CurrentUserClient {
  func currentUser() -> User?
  func logout() throws
  @MainActor func deleteAccount() async throws
}

public final class DefaultCurrentUserClient: CurrentUserClient {
  public init() {}

  public func currentUser() -> User? {
    guard let uid = Auth.auth().currentUser?.uid else { return nil }
    return User(uid: uid)
  }

  public func logout() throws {
    try Auth.auth().signOut()
  }

  @MainActor
  public func deleteAccount() async throws {
    try await Auth.auth().currentUser?.delete()
  }
}
