import Foundation

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

// 写真情報
struct Photo: Hashable, Sendable, Identifiable, Codable {
  let id: String
  let path: String?
  let title: String?
  let description: String?
  let takenDate: Date?
  let photographer: String?
  let createdAt: Date
  let updatedAt: Date

  init(
    id: String,
    path: String?,
    title: String? = nil,
    description: String? = nil,
    takenDate: Date? = nil,
    photographer: String? = nil,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.path = path
    self.title = title
    self.description = description
    self.takenDate = takenDate
    self.photographer = photographer
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  init?(documentID: String, data: [String: Any]) {
    guard let createdAtTimestamp = data["createdAt"] as? Timestamp,
      let updatedAtTimestamp = data["updatedAt"] as? Timestamp
    else {
      return nil
    }

    self.id = documentID
    self.path = data["path"] as? String
    self.title = data["title"] as? String
    self.description = data["description"] as? String
    self.photographer = data["photographer"] as? String

    if let takenDateTimestamp = data["takenDate"] as? Timestamp {
      self.takenDate = takenDateTimestamp.dateValue()
    } else {
      self.takenDate = nil
    }

    self.createdAt = createdAtTimestamp.dateValue()
    self.updatedAt = updatedAtTimestamp.dateValue()
  }
}
