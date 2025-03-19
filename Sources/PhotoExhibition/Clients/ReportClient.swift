import OSLog

#if SKIP
  import SkipFirebaseFunctions
#else
  import FirebaseFunctions
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ReportClient")

enum ReportType: String {
  case exhibition
  case photo
}

protocol ReportClient: Sendable {
  func report(type: ReportType, id: String, reason: String) async
}

actor DefaultReportClient: ReportClient {
  func report(type: ReportType, id: String, reason: String) async {
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
