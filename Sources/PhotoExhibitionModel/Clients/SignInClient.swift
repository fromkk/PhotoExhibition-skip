#if SKIP
  import SkipFirebaseAuth
  import SkipFirebaseFirestore
#else
  @preconcurrency import FirebaseAuth
  import FirebaseFirestore
#endif

public protocol SignInClient: Sendable {
  func signIn(email: String, password: String) async throws -> Member
}

public enum SignInClientError: Error, Sendable {
  case memberNotFound
  case invalidData
}

public actor DefaultSignInClient: SignInClient {
  public init() {}

  public func signIn(email: String, password: String) async throws -> Member {
    let user = try await Auth.auth().signIn(withEmail: email, password: password).user
    let uid = user.uid

    let db = Firestore.firestore()
    let document = try await db.collection("members").document(uid).getDocument()

    guard let data = document.data() else {
      throw SignInClientError.memberNotFound
    }
    guard let member = Member(documentID: uid, data: data) else {
      throw SignInClientError.invalidData
    }
    return member
  }
}
