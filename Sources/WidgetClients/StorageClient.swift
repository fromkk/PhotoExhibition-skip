import FirebaseStorage
import Foundation

public protocol StorageClient: Sendable {
  func url(_ path: String) async throws -> URL
}

public actor DefaultStorageClient: StorageClient {
  public init() {}

  public func url(_ path: String) async throws -> URL {
    let storage = Storage.storage()
    let reference = storage.reference().child(path)
    return try await reference.downloadURL()
  }
}
