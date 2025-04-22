import FirebaseFirestore

struct PhotoClient {
  var fetch: (String, String) async throws -> Photo
}

extension PhotoClient {
  static let liveValue: PhotoClient = Self(
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
