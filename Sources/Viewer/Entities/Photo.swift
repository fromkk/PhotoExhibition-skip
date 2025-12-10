@preconcurrency import FirebaseFirestore
import Foundation

// 写真情報
public struct Photo: Hashable, Sendable, Identifiable, Codable {
  public init(
    id: String? = nil,
    path: String? = nil,
    path_256x256: String? = nil,
    path_512x512: String? = nil,
    path_1024x1024: String? = nil,
    title: String? = nil,
    description: String? = nil,
    metadata: String? = nil,
    isThreeDimensional: Bool = false,
    sort: Int,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.path = path
    self.path_256x256 = path_256x256
    self.path_512x512 = path_512x512
    self.path_1024x1024 = path_1024x1024
    self.title = title
    self.description = description
    self.metadata = metadata
    self.isThreeDimensional = isThreeDimensional
    self.sort = sort
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  @DocumentID public var id: String?
  public let path: String?
  public let path_256x256: String?
  public let path_512x512: String?
  public let path_1024x1024: String?
  public let title: String?
  public let description: String?
  public let metadata: String?
  public let isThreeDimensional: Bool
  public let sort: Int
  public let createdAt: Date
  public let updatedAt: Date

  public var imagePath: String? {
    return path_1024x1024 ?? path_512x512 ?? path_256x256 ?? path
  }
}

extension Photo {
  public static let test = Self(
    id: "id",
    path: nil,
    path_256x256: nil,
    path_512x512: nil,
    path_1024x1024: nil,
    title: "title",
    description: "description",
    metadata: nil,
    isThreeDimensional: false,
    sort: 1,
    createdAt: Date(),
    updatedAt: Date()
  )
}
