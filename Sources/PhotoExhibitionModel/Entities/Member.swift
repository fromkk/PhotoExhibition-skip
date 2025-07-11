import Foundation

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

// 主催者情報
public struct Member: Hashable, Sendable, Identifiable, Codable {
  public init(
    id: String, name: String? = nil, icon: String? = nil, icon_256x256: String? = nil,
    icon_512x512: String? = nil, icon_1024x1024: String? = nil, postAgreement: Bool = false,
    createdAt: Date, updatedAt: Date
  ) {
    self.id = id
    self.name = name
    self.icon = icon
    self.icon_256x256 = icon_256x256
    self.icon_512x512 = icon_512x512
    self.icon_1024x1024 = icon_1024x1024
    self.postAgreement = postAgreement
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  public let id: String
  public let name: String?
  public let icon: String?
  public let icon_256x256: String?
  public let icon_512x512: String?
  public let icon_1024x1024: String?
  public let postAgreement: Bool
  public let createdAt: Date
  public let updatedAt: Date

  public init?(documentID: String, data: [String: Any]) {
    guard
      let createdAtTimestamp = data["createdAt"] as? Timestamp,
      let updatedAtTimestamp = data["updatedAt"] as? Timestamp
    else {
      return nil
    }

    self.id = documentID
    self.name = data["name"] as? String
    self.icon = data["icon"] as? String
    self.icon_256x256 = data["icon_256x256"] as? String
    self.icon_512x512 = data["icon_512x512"] as? String
    self.icon_1024x1024 = data["icon_1024x1024"] as? String
    self.postAgreement = data["postAgreement"] as? Bool ?? false
    self.createdAt = createdAtTimestamp.dateValue()
    self.updatedAt = updatedAtTimestamp.dateValue()
  }

  public var iconPath: String? {
    return icon_512x512 ?? icon_256x256 ?? icon_1024x1024 ?? icon
  }
}
