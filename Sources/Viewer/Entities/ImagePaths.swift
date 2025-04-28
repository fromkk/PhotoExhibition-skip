public struct ImagePaths: Hashable, Codable {
  public init(imagePath: String, imagePaths: [String]) {
    self.imagePath = imagePath
    self.imagePaths = imagePaths
  }

  public var imagePath: String
  public var imagePaths: [String]
}
