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
  let path_256x256: String?
  let path_512x512: String?
  let path_1024x1024: String?
  let title: String?
  let description: String?
  let takenDate: Date?
  let photographer: String?
  let createdAt: Date
  let updatedAt: Date

  init(
    id: String,
    path: String?,
    path_256x256: String? = nil,
    path_512x512: String? = nil,
    path_1024x1024: String? = nil,
    title: String? = nil,
    description: String? = nil,
    takenDate: Date? = nil,
    photographer: String? = nil,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.path = path
    self.path_256x256 = path_256x256
    self.path_512x512 = path_512x512
    self.path_1024x1024 = path_1024x1024
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
    self.path_256x256 = data["path_256x256"] as? String
    self.path_512x512 = data["path_512x512"] as? String
    self.path_1024x1024 = data["path_1024x1024"] as? String
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

  var imagePath: String? {
    return path_1024x1024 ?? path_512x512 ?? path_256x256 ?? path
  }
}
