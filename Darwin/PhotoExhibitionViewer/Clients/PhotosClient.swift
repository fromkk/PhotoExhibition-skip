import FirebaseFirestore

struct PhotosClient {
  var fetch: (String) async throws -> [Photo]
}

extension PhotosClient {
  static let liveValue: PhotosClient = Self(
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
