@preconcurrency import FirebaseFunctions
import OSLog

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!,
  category: "ContactClient"
)

public protocol ContactClient: Sendable {
  func send(title: String, content: String) async
}

public actor DefaultContactClient: ContactClient {
  public init() {}

  public func send(title: String, content: String) async {
    let functions = Functions.functions()
    let data: [String: Any] = [
      "title": title,
      "content": content,
    ]
    functions.httpsCallable("submitInquiry").call(
      data,
      completion: { result, error in
        if let error {
          logger.error("error \(error.localizedDescription)")
        }
      }
    )
  }
}
