import FirebaseAuth

public struct CurrentUserClient: Sendable {
  public var uid: @Sendable () -> String?
}

extension CurrentUserClient {
  public static let liveValue: CurrentUserClient = Self(
    uid: {
      Auth.auth().currentUser?.uid
    }
  )
}
