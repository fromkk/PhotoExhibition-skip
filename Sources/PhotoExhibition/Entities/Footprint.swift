import Foundation
import SwiftUI

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

/// 展示の足跡（閲覧記録）を表すエンティティ
struct Footprint: Hashable, Sendable, Identifiable, Codable {
  init(
    id: String,
    exhibitionId: String,
    userId: String,
    createdAt: Date
  ) {
    self.id = id
    self.exhibitionId = exhibitionId
    self.userId = userId
    self.createdAt = createdAt
  }

  let id: String
  let exhibitionId: String
  let userId: String
  let createdAt: Date

  init?(documentID: String, data: [String: Any]) {
    guard let exhibitionId = data["exhibitionId"] as? String,
      let userId = data["userId"] as? String,
      let createdAtTimestamp = data["createdAt"] as? Timestamp
    else {
      return nil
    }

    self.id = documentID
    self.exhibitionId = exhibitionId
    self.userId = userId
    self.createdAt = createdAtTimestamp.dateValue()
  }
}
