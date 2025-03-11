#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

protocol ExhibitionsClient: Sendable {
  func fetch() async throws -> [Exhibition]
}

actor DefaultExhibitionsClient: ExhibitionsClient {
  func fetch() async throws -> [Exhibition] {
    let exhibitions = try await Firestore.firestore().collection("exhibitions").getDocuments()
    return exhibitions.documents.compactMap {
      Exhibition(documentID: $0.documentID, data: $0.data())
    }
  }
}
