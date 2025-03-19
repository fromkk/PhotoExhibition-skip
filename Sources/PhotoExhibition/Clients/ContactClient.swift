import OSLog

#if SKIP
  import SkipFirebaseFunctions
#else
  @preconcurrency import FirebaseFunctions
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ContactClient")

protocol ContactClient: Sendable {
  func send(title: String, content: String) async
}

actor DefaultContactClient: ContactClient {
  func send(title: String, content: String) async {
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
      })
  }
}
