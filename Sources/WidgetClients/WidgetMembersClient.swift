import FirebaseFirestore
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "WidgetMembersClient")

public protocol WidgetMembersClient: Sendable {
  func fetch(_ uids: [String]) async throws -> [WidgetMember]
}

public actor DefaultWidgetMembersClient: WidgetMembersClient {
  public init() {}

  public func fetch(_ uids: [String]) async throws -> [WidgetMember] {
    guard !uids.isEmpty else { return [] }

    logger.info("fetch: \(uids.joined(separator: ", "))")

    let db = Firestore.firestore()
    // Firestoreでは一度に30件までしかin句で検索できないため、バッチ処理を行う
    var allMembers: [WidgetMember] = []

    // 空の配列の場合は早期リターン
    if uids.isEmpty {
      return []
    }

    // 30件ずつバッチ処理
    let batchSize = 30
    let batches = stride(from: 0, to: uids.count, by: batchSize).map {
      Array(uids[$0..<min($0 + batchSize, uids.count)])
    }

    for batch in batches {
      let currentBatch: [any Sendable] = batch.map { $0 }
      let snapshot = try await db.collection("members")
        .whereField("id", in: currentBatch)
        .getDocuments()

      let batchMembers = snapshot.documents.compactMap { document in
        WidgetMember(documentID: document.documentID, data: document.data())
      }

      allMembers.append(contentsOf: batchMembers)
    }

    return allMembers
  }
}
