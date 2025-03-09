import Foundation

// 写真情報
struct Photo: Hashable, Sendable, Identifiable {
  let id: String
  let name: String
  let filePath: URL
  let description: String?
  let takenDate: Date?
  let photographer: String
}
