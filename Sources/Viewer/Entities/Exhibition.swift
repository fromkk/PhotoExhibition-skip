@preconcurrency import FirebaseFirestore
import Foundation
import SwiftUI

// 展示状態（draft: 下書き, published: 公開, limited: 限定公開, banned: 管理者によるBAN）
public enum ExhibitionStatus: String, Hashable, Sendable, Codable, CaseIterable, Identifiable {
  case draft
  case published
  case limited
  case banned
  case unknown

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let stringValue = try container.decode(String.self)
    if let rawValue = ExhibitionStatus(rawValue: stringValue) {
      self = rawValue
    } else {
      self = .unknown
    }
  }

  public var id: String { rawValue }

  public static let editableCases: [Self] = [.draft, .published, .limited]

  public var localizedKey: LocalizedStringKey {
    LocalizedStringKey(rawValue)
  }
}

public struct Exhibition: Hashable, Identifiable, Codable, Sendable {
  public init(
    id: String? = nil,
    name: String,
    description: String? = nil,
    from: Date,
    to: Date,
    organizer: String,
    coverImagePath: String? = nil,
    cover_256x256: String? = nil,
    cover_512x512: String? = nil,
    cover_1024x1024: String? = nil,
    status: ExhibitionStatus,
    createdAt: Date,
    updatedAt: Date
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
    self.status = status
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  @DocumentID public var id: String?
  public let name: String
  public let description: String?
  public let from: Date
  public let to: Date
  public let organizer: String
  public let coverImagePath: String?
  public let cover_256x256: String?
  public let cover_512x512: String?
  public let cover_1024x1024: String?
  public let status: ExhibitionStatus
  public let createdAt: Date
  public let updatedAt: Date

  public var coverPath: String? {
    return cover_1024x1024 ?? cover_512x512 ?? cover_256x256 ?? coverImagePath
  }
}

extension Exhibition {
  public static let test: Exhibition = .init(
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
