import Foundation

// 主催者情報
struct Member: Hashable, Sendable, Identifiable {
  let id: String
  let name: String
  let icon: String?
}
