import Foundation

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif
// 写真展情報
struct Exhibition: Hashable, Sendable, Identifiable, Codable {
  let id: String
  let name: String
  let description: String?
  let from: Date
  let to: Date
  let location: String?  // 開催場所
  let organizer: String
  let createdAt: Date
  let updatedAt: Date

  init?(documentID: String, data: [String: Any]) {
    guard let name = data["name"] as? String,
      let fromTimestamp = data["from"] as? Timestamp,
      let toTimestamp = data["to"] as? Timestamp,
      let organizer = data["organizer"] as? String,
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
    self.location = data["location"] as? String
    self.organizer = organizer
    self.createdAt = createdAtTimestamp.dateValue()
    self.updatedAt = updatedAtTimestamp.dateValue()
  }
}
