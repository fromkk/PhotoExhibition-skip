import Foundation

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif
// 写真展情報
struct Exhibition: Hashable, Sendable, Identifiable, Codable {
  init(
    id: String, name: String, description: String? = nil, from: Date, to: Date,
    organizer: Member, coverImagePath: String? = nil, cover_256x256: String? = nil,
    cover_512x512: String? = nil, cover_1024x1024: String? = nil, createdAt: Date, updatedAt: Date
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.from = from
    self.to = to
    self.organizer = organizer
    self.coverImagePath = coverImagePath
    self.cover_256x256 = cover_256x256
    self.cover_512x512 = cover_512x512
    self.cover_1024x1024 = cover_1024x1024
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  let id: String
  let name: String
  let description: String?
  let from: Date
  let to: Date
  let organizer: Member
  let coverImagePath: String?
  let cover_256x256: String?
  let cover_512x512: String?
  let cover_1024x1024: String?
  let createdAt: Date
  let updatedAt: Date

  init?(documentID: String, data: [String: Any], organizer: Member) {
    guard let name = data["name"] as? String,
      let fromTimestamp = data["from"] as? Timestamp,
      let toTimestamp = data["to"] as? Timestamp,
      let createdAtTimestamp = data["createdAt"] as? Timestamp,
      let updatedAtTimestamp = data["updatedAt"] as? Timestamp
    else {
      return nil
    }

    self.id = documentID
    self.name = name
    self.description = data["description"] as? String
    self.from = fromTimestamp.dateValue()
    self.to = toTimestamp.dateValue()
    self.organizer = organizer
    self.coverImagePath = data["coverImagePath"] as? String
    self.cover_256x256 = data["cover_256x256"] as? String
    self.cover_512x512 = data["cover_512x512"] as? String
    self.cover_1024x1024 = data["cover_1024x1024"] as? String
    self.createdAt = createdAtTimestamp.dateValue()
    self.updatedAt = updatedAtTimestamp.dateValue()
  }

  var coverPath: String? {
    return cover_1024x1024 ?? cover_512x512 ?? cover_256x256 ?? coverImagePath
  }
}
