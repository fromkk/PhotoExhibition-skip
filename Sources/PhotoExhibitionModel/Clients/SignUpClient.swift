import Foundation

#if SKIP
  import SkipFirebaseAuth
  import SkipFirebaseFirestore
#else
  @preconcurrency import FirebaseAuth
  @preconcurrency import FirebaseFirestore
#endif

public protocol SignUpClient: Sendable {
  func signUp(email: String, password: String) async throws -> Member
}

public enum SignUpClientError: Error, Sendable {
  case invalidData
}

public actor DefaultSignUpClient: SignUpClient {
  public init() {}

  public func signUp(email: String, password: String) async throws -> Member {
    let user = try await Auth.auth().createUser(withEmail: email, password: password).user
    let uid = user.uid

    let db = Firestore.firestore()
    let memberData: [String: Any] = [
      "id": uid,
      "createdAt": Timestamp(date: Date()),
      "updatedAt": Timestamp(date: Date()),
    ]

    try await db.collection("members").document(uid).setData(memberData)

    guard let member = Member(documentID: uid, data: memberData) else {
      throw SignUpClientError.invalidData
    }
    return member
  }
}
