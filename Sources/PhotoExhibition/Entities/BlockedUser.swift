import Foundation

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

struct BlockedUser: Hashable, Codable, Sendable {
  let userId: String
  let createdAt: Date

  func toData() -> [String: any Sendable] {
    return [
      "userId": userId,
      "createdAt": Timestamp(date: createdAt),
    ]
  }
}
