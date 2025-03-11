#if SKIP
  import SkipFirebaseAuth
  import SkipFirebaseFirestore
#else
  @preconcurrency import FirebaseAuth
  import FirebaseFirestore
#endif

protocol SignInClient: Sendable {
  func signIn(email: String, password: String) async throws -> Member?
}

enum SignInClientError: Error, Sendable {
  case memberNotFound
}

actor DefaultSignInClient: SignInClient {
  func signIn(email: String, password: String) async throws -> Member? {
    let user = try await Auth.auth().signIn(withEmail: email, password: password).user
    let uid = user.uid

    let db = Firestore.firestore()
    let document = try await db.collection("members").document(uid).getDocument()

    guard let data = document.data() else {
      throw SignInClientError.memberNotFound
    }
    return Member(documentID: uid, data: data)
  }
}
