#if !SKIP

  import AuthenticationServices
  @preconcurrency import FirebaseAuth
  @preconcurrency import FirebaseFirestore

  protocol AuthClient: Sendable {
    func signInWithApple(authorization: ASAuthorization, nonce: String) async throws -> Member
  }

  enum AuthClientError: Error, Sendable {
    case invalidCredential
  }

  actor DefaultAuthClient: AuthClient {
    func signInWithApple(authorization: ASAuthorization, nonce: String) async throws -> Member {
      let auth = Auth.auth()

      guard
        let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
        let appleIDToken = appleIDCredential.identityToken,
        let idTokenString = String(data: appleIDToken, encoding: .utf8)
      else {
        throw AuthClientError.invalidCredential
      }
      let credential = OAuthProvider.appleCredential(
        withIDToken: idTokenString,
        rawNonce: nonce,
        fullName: appleIDCredential.fullName
      )

      let result = try await auth.signIn(with: credential)
      let uid = result.user.uid

      let firestore = Firestore.firestore()
      let memberRef = firestore.collection("members").document(uid)
      let snapshot = try await memberRef.getDocument()

      if snapshot.exists {
        let member = try snapshot.data(as: Member.self)
        return member
      } else {
        let now = Date()
        let member = Member(
          id: uid,
          createdAt: now,
          updatedAt: now
        )
        try memberRef.setData(from: member)
        return member
      }
    }
  }
#endif
