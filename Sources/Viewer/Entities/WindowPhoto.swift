public struct WindowPhoto: Hashable, Codable, Sendable {
  public init(exhibitionId: String, photoId: String) {
    self.exhibitionId = exhibitionId
    self.photoId = photoId
  }
  public let exhibitionId: String
  public let photoId: String
}
