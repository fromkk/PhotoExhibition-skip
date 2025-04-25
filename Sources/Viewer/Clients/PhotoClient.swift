import FirebaseFirestore

public struct PhotoClient: Sendable {
  public init(fetch: @escaping @Sendable (String, String) async throws -> Photo) {
    self.fetch = fetch
  }
  public var fetch: @Sendable (String, String) async throws -> Photo
}

extension PhotoClient {
  public static let liveValue: PhotoClient = Self(
    fetch: { exhibitionId, photoId in
      let firestore = Firestore.firestore()
      return try await firestore.collection("exhibitions")
        .document(exhibitionId)
        .collection("photos")
        .document(photoId)
        .getDocument(as: Photo.self)
    }
  )
}
