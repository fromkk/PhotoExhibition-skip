#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

protocol ExhibitionsClient: Sendable {
  func fetch() async throws -> [Exhibition]
  func create(data: [String: any Sendable]) async throws -> String
  func update(id: String, data: [String: any Sendable]) async throws
  func delete(id: String) async throws
}

actor DefaultExhibitionsClient: ExhibitionsClient {
  func fetch() async throws -> [Exhibition] {
    let firestore = Firestore.firestore()
    let exhibitions = try await firestore.collection("exhibitions")
      .getDocuments()
    var result: [Exhibition] = []
    for document in exhibitions.documents {
      let data = document.data()
      guard let organizerUID = data["organizer"] as? String else {
        continue
      }

      // キャッシュからメンバーを取得を試みる
      if let cachedMember = await DefaultMemberCacheClient.shared.getMember(withID: organizerUID),
        let exhibition = Exhibition(
          documentID: document.documentID, data: data, organizer: cachedMember)
      {
        result.append(exhibition)
      } else {
        // キャッシュにない場合はFirestoreから取得
        let organizerReference = firestore.collection("members").document(organizerUID)
        let organizerDocument = try await organizerReference.getDocument()

        guard
          let organizerData = organizerDocument.data(),
          let organizer = Member(
            documentID: organizerDocument.documentID, data: organizerData),
          let exhibition = Exhibition(
            documentID: document.documentID, data: data, organizer: organizer)
        else {
          continue
        }

        // 取得したメンバーをキャッシュに保存
        await DefaultMemberCacheClient.shared.setMember(organizer)
        result.append(exhibition)
      }
    }

    return result
  }

  func create(data: [String: any Sendable]) async throws -> String {
    let documentReference = try await Firestore.firestore().collection(
      "exhibitions"
    ).addDocument(
      data: data)
    return documentReference.documentID
  }

  func update(id: String, data: [String: any Sendable]) async throws {
    try await Firestore.firestore().collection("exhibitions").document(id)
      .updateData(data)
  }

  func delete(id: String) async throws {
    try await Firestore.firestore().collection("exhibitions").document(id)
      .delete()
  }
}
