import OSLog

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ExhibitionsClient")

protocol ExhibitionsClient: Sendable {
  func fetch(now: Date, cursor: String?) async throws -> (
    exhibitions: [Exhibition], nextCursor: String?
  )
  func create(id: String, data: [String: any Sendable]) async throws
  func update(id: String, data: [String: any Sendable]) async throws
  func delete(id: String) async throws
  func get(id: String) async throws -> Exhibition
  func fetchMyExhibitions(organizerID: String, cursor: String?) async throws -> (
    exhibitions: [Exhibition], nextCursor: String?
  )
}

actor DefaultExhibitionsClient: ExhibitionsClient {
  private let pageSize = 10

  func fetch(now: Date, cursor: String?) async throws -> (
    exhibitions: [Exhibition], nextCursor: String?
  ) {
    logger.info("fetch cursor: \(String(describing: cursor))")
    let firestore = Firestore.firestore()

    var query = firestore.collection("exhibitions")
      .whereField("from", isLessThanOrEqualTo: Timestamp(date: now))
      .whereField("to", isGreaterThanOrEqualTo: Timestamp(date: now))
      .whereField("status", isEqualTo: ExhibitionStatus.published.rawValue)
      .order(by: "to", descending: true)
      #if SKIP
        .limit(to: Int64(pageSize))
      #else
        .limit(to: pageSize)
      #endif

    if let cursor = cursor {
      let cursorDocument = try await firestore.collection("exhibitions").document(cursor)
        .getDocument()
      query = query.start(afterDocument: cursorDocument)
    }

    let exhibitions = try await query.getDocuments()
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

    let nextCursor =
      exhibitions.documents.count == pageSize ? exhibitions.documents.last?.documentID : nil
    return (result, nextCursor)
  }

  func create(id: String, data: [String: any Sendable]) async throws {
    try await Firestore.firestore().collection("exhibitions").document(id)
      .setData(data)
  }

  func update(id: String, data: [String: any Sendable]) async throws {
    try await Firestore.firestore().collection("exhibitions").document(id)
      .updateData(data)
  }

  func delete(id: String) async throws {
    try await Firestore.firestore().collection("exhibitions").document(id)
      .delete()
  }

  func get(id: String) async throws -> Exhibition {
    let firestore = Firestore.firestore()
    let document = try await firestore.collection("exhibitions").document(id).getDocument()

    guard let data = document.data(),
      let organizerUID = data["organizer"] as? String
    else {
      throw NSError(
        domain: "ExhibitionsClient", code: 404,
        userInfo: [
          NSLocalizedDescriptionKey: "Exhibition not found or invalid data"
        ])
    }

    // キャッシュからメンバーを取得を試みる
    if let cachedMember = await DefaultMemberCacheClient.shared.getMember(withID: organizerUID),
      let exhibition = Exhibition(
        documentID: document.documentID, data: data, organizer: cachedMember)
    {
      return exhibition
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
        throw NSError(
          domain: "ExhibitionsClient", code: 404,
          userInfo: [
            NSLocalizedDescriptionKey: "Failed to create exhibition from data"
          ])
      }

      // 取得したメンバーをキャッシュに保存
      await DefaultMemberCacheClient.shared.setMember(organizer)
      return exhibition
    }
  }

  func fetchMyExhibitions(organizerID: String, cursor: String?) async throws -> (
    exhibitions: [Exhibition], nextCursor: String?
  ) {
    logger.info("fetchMyExhibitions cursor: \(String(describing: cursor))")
    let firestore = Firestore.firestore()

    var query = firestore.collection("exhibitions")
      .whereField("organizer", isEqualTo: organizerID)
      .order(by: "createdAt", descending: true)
      #if SKIP
        .limit(to: Int64(pageSize))
      #else
        .limit(to: pageSize)
      #endif

    if let cursor = cursor {
      let cursorDocument = try await firestore.collection("exhibitions").document(cursor)
        .getDocument()
      query = query.start(afterDocument: cursorDocument)
    }

    let exhibitions = try await query.getDocuments()
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

    let nextCursor =
      exhibitions.documents.count == pageSize ? exhibitions.documents.last?.documentID : nil
    return (result, nextCursor)
  }
}
