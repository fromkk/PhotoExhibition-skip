import FirebaseFirestore
import Foundation
import SwiftUI

// 展示状態（draft: 下書き, published: 公開, banned: 管理者によるBAN）
public enum WidgetExhibitionStatus: String, Hashable, Sendable, Codable, CaseIterable, Identifiable
{
  case draft
  case published
  case banned

  public var id: String { rawValue }

  public static let editableCases: [Self] = [.draft, .published]

  public var localizedKey: LocalizedStringKey {
    LocalizedStringKey(rawValue)
  }
}

// 写真展情報
public struct WidgetExhibition: Hashable, Sendable, Identifiable, Codable {
  public init(
    id: String, name: String, description: String? = nil, from: Date, to: Date,
    organizer: WidgetMember, coverImagePath: String? = nil, cover_256x256: String? = nil,
    cover_512x512: String? = nil, cover_1024x1024: String? = nil,
    status: WidgetExhibitionStatus = .draft,
    createdAt: Date, updatedAt: Date
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

  public let id: String
  public let name: String
  public let description: String?
  public let from: Date
  public let to: Date
  public let organizer: WidgetMember
  public let coverImagePath: String?
  public let cover_256x256: String?
  public let cover_512x512: String?
  public let cover_1024x1024: String?
  public let status: WidgetExhibitionStatus
  public let createdAt: Date
  public let updatedAt: Date

  public init?(documentID: String, data: [String: Any], organizer: WidgetMember) {
    guard let name = data["name"] as? String,
      let fromTimestamp = data["from"] as? Timestamp,
      let toTimestamp = data["to"] as? Timestamp,
      let statusString = data["status"] as? String,
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
    self.coverImagePath = data["coverImagePath"] as? String
    self.cover_256x256 = data["cover_256x256"] as? String
    self.cover_512x512 = data["cover_512x512"] as? String
    self.cover_1024x1024 = data["cover_1024x1024"] as? String
    self.status = WidgetExhibitionStatus(rawValue: statusString) ?? .published
    self.createdAt = createdAtTimestamp.dateValue()
    self.updatedAt = updatedAtTimestamp.dateValue()
  }

  public var coverPath: String? {
    return cover_1024x1024 ?? cover_512x512 ?? cover_256x256 ?? coverImagePath
  }
}
