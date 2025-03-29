import FirebaseStorage
import Foundation

public protocol WidgetStorageClient: Sendable {
  func url(_ path: String) async throws -> URL
}

public actor DefaultWidgetStorageClient: WidgetStorageClient {
  public init() {}

  public func url(_ path: String) async throws -> URL {
    let storage = Storage.storage()
    let reference = storage.reference(withPath: path)
    return try await reference.downloadURL()
  }
}
