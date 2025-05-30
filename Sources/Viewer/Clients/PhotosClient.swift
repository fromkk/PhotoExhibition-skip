import FirebaseFirestore

public struct PhotosClient: Sendable {
  public init(fetch: @escaping @Sendable (String) async throws -> [Photo]) {
    self.fetch = fetch
  }
  public var fetch: @Sendable (String) async throws -> [Photo]
}

extension PhotosClient {
  public static let liveValue: PhotosClient = Self(
    fetch: { exhibitionId in
      let firestore = Firestore.firestore()
      let query = try await firestore.collection("exhibitions")
        .document(exhibitionId)
        .collection("photos")
        .order(by: "sort", descending: false)
        .order(by: "createdAt", descending: false)
        .getDocuments()
      return query.documents.compactMap {
        try? $0.data(as: Photo.self)
      }
    }
  )
}
