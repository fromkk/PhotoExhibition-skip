#if SKIP
  import SkipFirebaseFirestore
#else
  @preconcurrency import FirebaseFirestore
#endif

protocol MembersClient: Sendable {
  func fetch(_ UIDs: [String]) async throws -> [Member]
}

actor DefaultMembersClient: MembersClient {
  func fetch(_ UIDs: [String]) async throws -> [Member] {
    let db = Firestore.firestore()
    // Firestoreでは一度に30件までしかin句で検索できないため、バッチ処理を行う
    var allMembers: [Member] = []

    // 空の配列の場合は早期リターン
    if UIDs.isEmpty {
      return []
    }

    // 30件ずつバッチ処理
    let batchSize = 30
    let batches = stride(from: 0, to: UIDs.count, by: batchSize).map {
      Array(UIDs[$0..<min($0 + batchSize, UIDs.count)])
    }

    for batch in batches {
      let currentBatch: [any Sendable] = batch.map { $0 }
      let snapshot = try await db.collection("members")
        .whereField("id", in: currentBatch)
        .getDocuments()

      let batchMembers = snapshot.documents.compactMap { document in
        Member(documentID: document.documentID, data: document.data())
      }

      allMembers.append(contentsOf: batchMembers)
    }

    return allMembers
  }
}
