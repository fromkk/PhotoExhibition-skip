import FirebaseFirestore
import Foundation
import SwiftUI

// 展示状態（draft: 下書き, published: 公開, banned: 管理者によるBAN）
enum ExhibitionStatus: String, Hashable, Sendable, Codable, CaseIterable, Identifiable {
  case draft
  case published
  case banned

  var id: String { rawValue }

  static let editableCases: [Self] = [.draft, .published]

  var localizedKey: LocalizedStringKey {
    LocalizedStringKey(rawValue)
  }
}

struct Exhibition: Hashable, Identifiable, Codable {
  @DocumentID var id: String?
  let name: String
  let description: String?
  let from: Date
  let to: Date
  let organizer: String
  let coverImagePath: String?
  let cover_256x256: String?
  let cover_512x512: String?
  let cover_1024x1024: String?
  let status: ExhibitionStatus
  let createdAt: Date
  let updatedAt: Date

  var coverPath: String? {
    return cover_1024x1024 ?? cover_512x512 ?? cover_256x256 ?? coverImagePath
  }
}

extension Exhibition {
  static let test: Exhibition = .init(
    id: "id",
    name: "name",
    description: "description",
    from: Date(),
    to: Date(),
    organizer: "organizer",
    coverImagePath: nil,
    cover_256x256: nil,
    cover_512x512: nil,
    cover_1024x1024: nil,
    status: .published,
    createdAt: Date(),
    updatedAt: Date()
  )
}
