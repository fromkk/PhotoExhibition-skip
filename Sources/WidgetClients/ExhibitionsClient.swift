import FirebaseFirestore
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ExhibitionsClient")

public protocol ExhibitionsClient: Sendable {
  func fetch(now: Date, cursor: String?) async throws -> (
    exhibitions: [Exhibition], nextCursor: String?
  )
  func get(id: String) async throws -> Exhibition
}

public actor DefaultExhibitionsClient: ExhibitionsClient {
  private let pageSize = 30

  private let membersClient: any MembersClient
  public init(membersClient: any MembersClient = DefaultMembersClient()) {
    self.membersClient = membersClient
  }

  public func fetch(now: Date, cursor: String?) async throws -> (
    exhibitions: [Exhibition], nextCursor: String?
  ) {
    logger.info("fetch cursor: \(String(describing: cursor))")
    let firestore = Firestore.firestore()

    var query = firestore.collection("exhibitions")
      .whereField("from", isLessThanOrEqualTo: Timestamp(date: now))
      .whereField("to", isGreaterThanOrEqualTo: Timestamp(date: now))
      .whereField("status", isEqualTo: ExhibitionStatus.published.rawValue)
      .order(by: "from", descending: true)
      .limit(to: pageSize)

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

      guard let member = try await membersClient.fetch([organizerUID]).first else {
        continue
      }

      guard
        let exhibition = Exhibition(documentID: document.documentID, data: data, organizer: member)
      else {
        continue
      }
      result.append(exhibition)
    }

    let nextCursor =
      exhibitions.documents.count == pageSize ? exhibitions.documents.last?.documentID : nil
    return (result, nextCursor)
  }

  public func get(id: String) async throws -> Exhibition {
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
    if let member = try await membersClient.fetch([organizerUID]).first,
      let exhibition = Exhibition(
        documentID: document.documentID, data: data, organizer: member)
    {
      return exhibition
    } else {
      throw NSError(
        domain: "ExhibitionsClient", code: 404,
        userInfo: [
          NSLocalizedDescriptionKey: "Failed to create exhibition from data"
        ])
    }
  }
}
