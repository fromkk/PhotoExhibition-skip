import OSLog

#if SKIP
  import SkipFirebaseFunctions
#else
  import FirebaseFunctions
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ReportClient")

public enum ReportType: String, Sendable {
  case exhibition
  case photo
}

public protocol ReportClient: Sendable {
  func report(type: ReportType, id: String, reason: String) async
}

public actor DefaultReportClient: ReportClient {
  public init() {}

  public func report(type: ReportType, id: String, reason: String) async {
    let functions = Functions.functions()
    let data: [String: Any] = [
      "type": type.rawValue,
      "id": id,
      "reason": reason,
    ]

    functions.httpsCallable("reportContent").call(
      data,
      completion: { result, error in
        if let error {
          logger.error("error \(error.localizedDescription)")
        }
      })
  }
}
