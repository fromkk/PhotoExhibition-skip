@preconcurrency import FirebaseFirestore
import Foundation

// 写真情報
struct Photo: Hashable, Sendable, Identifiable, Codable {
  @DocumentID var id: String?
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

  var imagePath: String? {
    return path_1024x1024 ?? path_512x512 ?? path_256x256 ?? path
  }
}

extension Photo {
  static let test = Self(
    id: "id",
    path: nil,
    path_256x256: nil,
    path_512x512: nil,
    path_1024x1024: nil,
    title: "title",
    description: "description",
    metadata: nil,
    sort: 1,
    createdAt: Date(),
    updatedAt: Date()
  )
}
