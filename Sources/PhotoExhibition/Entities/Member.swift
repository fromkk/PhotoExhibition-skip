import Foundation

// 主催者情報
struct Member: Hashable, Sendable, Identifiable, Codable {
  let id: String
  let name: String
  let icon: String?
}
