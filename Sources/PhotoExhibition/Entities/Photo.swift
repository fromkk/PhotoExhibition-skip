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
  let metadata: String?
  let sort: Int
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
    metadata: String?,
    sort: Int = 0,
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
    self.metadata = metadata
    self.sort = sort
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
    self.metadata = data["metadata"] as? String
    self.sort = data["sort"] as? Int ?? 0
    self.createdAt = createdAtTimestamp.dateValue()
    self.updatedAt = updatedAtTimestamp.dateValue()
  }

  var imagePath: String? {
    return path_1024x1024 ?? path_512x512 ?? path_256x256 ?? path
  }
}
