import OSLog

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FootprintClient")

protocol FootprintClient: Sendable {
  func recordFootprint(
    exhibitionId: String, userId: String
  ) async throws -> Footprint

  func fetchFootprints(exhibitionId: String, cursor: String?) async throws -> (
    footprints: [Footprint], nextCursor: String?
  )

  func toggleFootprint(
    exhibitionId: String, userId: String
  ) async throws -> Bool

  func getVisitorCount(exhibitionId: String) async throws -> Int

  func hasAddedFootprint(exhibitionId: String, userId: String) async throws -> Bool
}

actor DefaultFootprintClient: FootprintClient {
  private let pageSize = 20

  func recordFootprint(
    exhibitionId: String, userId: String
  ) async throws -> Footprint {
    logger.info("recordFootprint for exhibition: \(exhibitionId) user: \(userId)")

    let firestore = Firestore.firestore()
    let documentID = UUID().uuidString
    let data: [String: Any] = [
      "userId": userId,
      "createdAt": Timestamp(date: Date()),
    ]

    try await firestore.collection("exhibitions").document(exhibitionId).collection("footprints")
      .document(documentID).setData(data)

    return Footprint(
      id: documentID,
      exhibitionId: exhibitionId,
      userId: userId,
      createdAt: Date()
    )
  }

  func fetchFootprints(exhibitionId: String, cursor: String?) async throws -> (
    footprints: [Footprint], nextCursor: String?
  ) {
    logger.info(
      "fetchFootprints for exhibition: \(exhibitionId) cursor: \(String(describing: cursor))")

    let firestore = Firestore.firestore()

    var query = firestore.collection("exhibitions").document(exhibitionId).collection("footprints")
      .order(by: "createdAt", descending: true)
      #if SKIP
        .limit(to: Int64(pageSize))
      #else
        .limit(to: pageSize)
      #endif

    if let cursor = cursor {
      let cursorDocument = try await firestore.collection("exhibitions").document(exhibitionId)
        .collection("footprints").document(cursor)
        .getDocument()
      query = query.start(afterDocument: cursorDocument)
    }

    let footprintsSnapshot = try await query.getDocuments()
    var result: [Footprint] = []

    for document in footprintsSnapshot.documents {
      let data = document.data()
      // exhibitionIdをデータに追加（新しいパス構造のため、documentに含まれていない）
      var footprintData = data
      footprintData["exhibitionId"] = exhibitionId
      if let footprint = Footprint(documentID: document.documentID, data: footprintData) {
        result.append(footprint)
      }
    }

    let nextCursor =
      footprintsSnapshot.documents.count == pageSize
      ? footprintsSnapshot.documents.last?.documentID : nil

    return (result, nextCursor)
  }

  func toggleFootprint(
    exhibitionId: String, userId: String
  ) async throws -> Bool {
    logger.info("toggleFootprint for exhibition: \(exhibitionId) user: \(userId)")

    let firestore = Firestore.firestore()

    // ユーザーがすでに足跡を残しているか確認
    let hasFootprint = try await hasAddedFootprint(exhibitionId: exhibitionId, userId: userId)

    if hasFootprint {
      // 足跡がある場合は削除
      let query = firestore.collection("exhibitions").document(exhibitionId).collection(
        "footprints"
      )
      .whereField("userId", isEqualTo: userId)

      let snapshot = try await query.getDocuments()

      for document in snapshot.documents {
        try await firestore.collection("exhibitions").document(exhibitionId).collection(
          "footprints"
        ).document(document.documentID).delete()
        logger.info("Deleted footprint for user: \(userId) in exhibition: \(exhibitionId)")
      }

      return false
    } else {
      // 足跡がない場合は追加
      let documentID = UUID().uuidString
      let data: [String: Any] = [
        "userId": userId,
        "createdAt": Timestamp(date: Date()),
      ]

      try await firestore.collection("exhibitions").document(exhibitionId).collection("footprints")
        .document(documentID).setData(data)
      logger.info("Added footprint for user: \(userId) in exhibition: \(exhibitionId)")

      return true
    }
  }

  func getVisitorCount(exhibitionId: String) async throws -> Int {
    logger.info("getVisitorCount for exhibition: \(exhibitionId)")

    let firestore = Firestore.firestore()

    let query = firestore.collection("exhibitions").document(exhibitionId).collection("footprints")

    let snapshot = try await query.count.getAggregation(source: .server)

    #if SKIP
      return Int(snapshot.count)
    #else
      return snapshot.count.intValue
    #endif
  }

  func hasAddedFootprint(exhibitionId: String, userId: String) async throws -> Bool {
    logger.info("hasAddedFootprint for exhibition: \(exhibitionId) user: \(userId)")

    let firestore = Firestore.firestore()

    let query = firestore.collection("exhibitions").document(exhibitionId).collection("footprints")
      .whereField("userId", isEqualTo: userId)
      .limit(to: 1)

    let snapshot = try await query.getDocuments()

    return !snapshot.documents.isEmpty
  }
}
