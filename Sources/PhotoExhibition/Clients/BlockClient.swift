import Foundation
import OSLog

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BlockClient")

protocol BlockClient: Sendable {
  func blockUser(_ userId: String) async throws
  func unblockUser(_ userId: String) async throws
  func isBlocked(_ userId: String) async throws -> Bool
}

actor DefaultBlockClient: BlockClient {
  private let db: Firestore
  private let currentUserId: String

  init(db: Firestore = Firestore.firestore(), currentUserId: String) {
    self.db = db
    self.currentUserId = currentUserId
  }

  func blockUser(_ userId: String) async throws {
    logger.info("blockUser: \(userId)")

    let blockedUser = BlockedUser(userId: userId, createdAt: Date())
    try await db.collection("members")
      .document(currentUserId)
      .collection("blocked")
      .document(userId)
      .setData(blockedUser.toData())
  }

  func unblockUser(_ userId: String) async throws {
    logger.info("unblockUser: \(userId)")

    try await db.collection("members")
      .document(currentUserId)
      .collection("blocked")
      .document(userId)
      .delete()
  }

  func isBlocked(_ userId: String) async throws -> Bool {
    logger.info("isBlocked checking: \(userId)")

    let document = try await db.collection("members")
      .document(currentUserId)
      .collection("blocked")
      .document(userId)
      .getDocument()

    return document.exists
  }
}
