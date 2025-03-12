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
    organizer: Member, createdAt: Date, updatedAt: Date
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.from = from
    self.to = to
    self.organizer = organizer
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  let id: String
  let name: String
  let description: String?
  let from: Date
  let to: Date
  let organizer: Member
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
    self.createdAt = createdAtTimestamp.dateValue()
    self.updatedAt = updatedAtTimestamp.dateValue()
  }
}
