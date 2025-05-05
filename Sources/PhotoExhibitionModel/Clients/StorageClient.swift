import Foundation

#if SKIP
  import SkipFirebaseStorage
#else
  @preconcurrency import FirebaseStorage
#endif

public protocol StorageClient: Sendable {
  func url(_ path: String) async throws -> URL
  @discardableResult
  func upload(from url: URL, to path: String) async throws -> URL
  func delete(path: String) async throws
}

public actor DefaultStorageClient: StorageClient {
  public static let shared = DefaultStorageClient()

  public init() {}

  public func url(_ path: String) async throws -> URL {
    let storage = Storage.storage()
    let reference = storage.reference().child(path)
    return try await reference.downloadURL()
  }

  @discardableResult
  public func upload(from url: URL, to path: String) async throws -> URL {
    let storage = Storage.storage()
    let reference = storage.reference().child(path)
    let metadata = StorageMetadata()
    if url.pathExtension == "png" {
      metadata.contentType = "image/png"
    } else {
      metadata.contentType = "image/jpeg"
    }
    _ = try await reference.putFileAsync(from: url, metadata: metadata)
    return try await reference.downloadURL()
  }

  public func delete(path: String) async throws {
    let storage = Storage.storage()
    let reference = storage.reference().child(path)
    try await reference.delete()
  }
}
