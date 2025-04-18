import FirebaseFirestore

struct ExhibitionsClient {
  var fetch: @Sendable (_ now: Date, _ cursor: String?) async throws -> ([Exhibition], String?)
}

extension ExhibitionsClient {
  static private let pageSize = 30
  static let liveValue: ExhibitionsClient = Self(
    fetch: { now, cursor in
      let firestore = Firestore.firestore()
      var query = firestore.collection("exhibitions")
        .whereField("from", isLessThanOrEqualTo: Timestamp(date: now))
        .whereField("to", isGreaterThanOrEqualTo: Timestamp(date: now))
        .whereField("status", isEqualTo: ExhibitionStatus.published.rawValue)
        .order(by: "from", descending: true)
        .limit(to: Self.pageSize)

      if let cursor {
        let cursorDocument = try await firestore.collection("exhibitions").document(cursor)
          .getDocument()
        query = query.start(afterDocument: cursorDocument)
      }

      let snapshot = try await query.getDocuments()
      var lastDocument = snapshot.documents.last
      let exhibitions = snapshot.documents.compactMap {
        try? $0.data(as: Exhibition.self)
      }
      return (exhibitions, lastDocument?.documentID)
    }
  )
}
