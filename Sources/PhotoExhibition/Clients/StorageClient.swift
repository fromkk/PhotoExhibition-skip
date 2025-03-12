import Foundation

#if SKIP
  import SkipFirebaseStorage
#else
  import FirebaseStorage
#endif

protocol StorageClient: Sendable {
  func url(_ path: String) async throws -> URL
  func upload(from url: URL, to path: String) async throws -> URL
  func delete(path: String) async throws
}

actor DefaultStorageClient: StorageClient {
  func url(_ path: String) async throws -> URL {
    let storage = Storage.storage()
    let reference = storage.reference().child(path)
    return try await reference.downloadURL()
  }

  func upload(from url: URL, to path: String) async throws -> URL {
    let storage = Storage.storage()
    let reference = storage.reference().child(path)
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    reference.putFile(from: url, metadata: metadata)
    return try await reference.downloadURL()
  }

  func delete(path: String) async throws {
    let storage = Storage.storage()
    let reference = storage.reference().child(path)
    try await reference.delete()
  }
}
