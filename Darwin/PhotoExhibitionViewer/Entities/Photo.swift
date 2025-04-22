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
