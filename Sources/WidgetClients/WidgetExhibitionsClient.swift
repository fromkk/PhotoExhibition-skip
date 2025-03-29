import FirebaseFirestore
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "WidgetExhibitionsClient")

public protocol WidgetExhibitionsClient: Sendable {
  func fetch(now: Date, cursor: String?) async throws -> (
    exhibitions: [WidgetExhibition], nextCursor: String?
  )
  func get(id: String) async throws -> WidgetExhibition
}

public actor DefaultWidgetExhibitionsClient: WidgetExhibitionsClient {
  private let pageSize = 30

  private let membersClient: any WidgetMembersClient
  public init(membersClient: any WidgetMembersClient = DefaultWidgetMembersClient()) {
    self.membersClient = membersClient
  }

  public func fetch(now: Date, cursor: String?) async throws -> (
    exhibitions: [WidgetExhibition], nextCursor: String?
  ) {
    logger.info("fetch cursor: \(String(describing: cursor))")
    let firestore = Firestore.firestore()

    var query = firestore.collection("exhibitions")
      .whereField("from", isLessThanOrEqualTo: Timestamp(date: now))
      .whereField("to", isGreaterThanOrEqualTo: Timestamp(date: now))
      .whereField("status", isEqualTo: WidgetExhibitionStatus.published.rawValue)
      .order(by: "from", descending: true)
      .limit(to: pageSize)

    if let cursor = cursor {
      let cursorDocument = try await firestore.collection("exhibitions").document(cursor)
        .getDocument()
      query = query.start(afterDocument: cursorDocument)
    }

    let exhibitions = try await query.getDocuments()
    var result: [WidgetExhibition] = []

    for document in exhibitions.documents {
      let data = document.data()
      guard let organizerUID = data["organizer"] as? String else {
        continue
      }

      guard let member = try await membersClient.fetch([organizerUID]).first else {
        continue
      }

      guard
        let exhibition = WidgetExhibition(documentID: document.documentID, data: data, organizer: member)
      else {
        continue
      }
      result.append(exhibition)
    }

    let nextCursor = result.last?.id
    return (exhibitions: result, nextCursor: nextCursor)
  }

  public func get(id: String) async throws -> WidgetExhibition {
    logger.info("get id: \(id)")
    let firestore = Firestore.firestore()
    let document = try await firestore.collection("exhibitions").document(id).getDocument()
    guard let data = document.data() else {
      throw WidgetExhibitionsClientError.documentNotFound
    }
    guard let organizerUID = data["organizer"] as? String else {
      throw WidgetExhibitionsClientError.invalidData
    }
    guard let organizer = try await membersClient.fetch([organizerUID]).first else {
      throw WidgetExhibitionsClientError.organizerNotFound
    }
    guard let exhibition = WidgetExhibition(documentID: document.documentID, data: data, organizer: organizer) else {
      throw WidgetExhibitionsClientError.invalidData
    }
    return exhibition
  }
}

public enum WidgetExhibitionsClientError: Error, Sendable {
  case documentNotFound
  case organizerNotFound
  case invalidData
}
