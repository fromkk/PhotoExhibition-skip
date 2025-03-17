#if SKIP
  import SkipFirebaseAuth
#else
  import FirebaseAuth
#endif

struct User: Hashable {
  let uid: String
}

protocol CurrentUserClient {
  func currentUser() -> User?
  func logout() throws
  @MainActor func deleteAccount() async throws
}

final class DefaultCurrentUserClient: CurrentUserClient {
  func currentUser() -> User? {
    guard let uid = Auth.auth().currentUser?.uid else { return nil }
    return User(uid: uid)
  }

  func logout() throws {
    try Auth.auth().signOut()
  }

  @MainActor
  func deleteAccount() async throws {
    try await Auth.auth().currentUser?.delete()
  }
}
