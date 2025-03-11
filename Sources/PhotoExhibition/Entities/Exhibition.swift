import Foundation

// 写真展情報
struct Exhibition: Hashable, Sendable, Identifiable, Codable {
  let id: String
  let name: String
  let description: String?
  let from: Date
  let to: Date
  let location: String  // 開催場所
  let organizer: Member
  let photos: [Photo]  // 写真のリスト
  let createdAt: Date
  let updatedAt: Date
}
