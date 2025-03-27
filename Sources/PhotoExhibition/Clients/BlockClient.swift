import Foundation
import OSLog

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BlockClient")

protocol BlockClient: Sendable {
  func blockUser(currentUserId: String, blockUserId: String) async throws
  func unblockUser(currentUserId: String, blockUserId: String) async throws
  func isBlocked(currentUserId: String, blockUserId: String) async throws -> Bool
  func fetchBlockedUserIds(currentUserId: String) async throws -> [String]
}

actor DefaultBlockClient: BlockClient {
  static let shared = DefaultBlockClient()

  private let db: Firestore

  init(db: Firestore = Firestore.firestore()) {
    self.db = db
  }

  func blockUser(currentUserId: String, blockUserId: String) async throws {
    logger.info("blockUser: currentUser=\(currentUserId), blockUser=\(blockUserId)")

    let blockedUser = BlockedUser(userId: blockUserId, createdAt: Date())
    try await db.collection("members")
      .document(currentUserId)
      .collection("blocked")
      .document(blockUserId)
      .setData(blockedUser.toData())
  }

  func unblockUser(currentUserId: String, blockUserId: String) async throws {
    logger.info("unblockUser: currentUser=\(currentUserId), blockUser=\(blockUserId)")

    try await db.collection("members")
      .document(currentUserId)
      .collection("blocked")
      .document(blockUserId)
      .delete()
  }

  func isBlocked(currentUserId: String, blockUserId: String) async throws -> Bool {
    logger.info("isBlocked checking: currentUser=\(currentUserId), blockUser=\(blockUserId)")

    let document = try await db.collection("members")
      .document(currentUserId)
      .collection("blocked")
      .document(blockUserId)
      .getDocument()

    return document.exists
  }

  func fetchBlockedUserIds(currentUserId: String) async throws -> [String] {
    logger.info("fetchBlockedUserIds for user: \(currentUserId)")

    let snapshot = try await db.collection("members")
      .document(currentUserId)
      .collection("blocked")
      .getDocuments()

    var userIds: [String] = []
    for document in snapshot.documents {
      let data = document.data()
      if let userId = data["userId"] as? String {
        userIds.append(userId)
      }
    }

    logger.info("Found \(userIds.count) blocked users")
    return userIds
  }
}
