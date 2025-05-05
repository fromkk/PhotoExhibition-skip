import Foundation

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

public struct BlockedUser: Hashable, Codable, Sendable {
  public let userId: String
  public let createdAt: Date

  public init(userId: String, createdAt: Date) {
    self.userId = userId
    self.createdAt = createdAt
  }

  public func toData() -> [String: any Sendable] {
    return [
      "userId": userId,
      "createdAt": Timestamp(date: createdAt),
    ]
  }
}
