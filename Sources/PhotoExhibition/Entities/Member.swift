import Foundation

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

// 主催者情報
struct Member: Hashable, Sendable, Identifiable, Codable {
  init(id: String, name: String, icon: String? = nil, createdAt: Date, updatedAt: Date) {
    self.id = id
    self.name = name
    self.icon = icon
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  let id: String
  let name: String
  let icon: String?
  let createdAt: Date
  let updatedAt: Date

  init?(documentID: String, data: [String: Any]) {
    guard let name = data["name"] as? String,
      let createdAtTimestamp = data["createdAt"] as? Timestamp,
      let updatedAtTimestamp = data["updatedAt"] as? Timestamp
    else {
      return nil
    }

    self.id = documentID
    self.name = name
    self.icon = data["icon"] as? String
    self.createdAt = createdAtTimestamp.dateValue()
    self.updatedAt = updatedAtTimestamp.dateValue()
  }
}
