import FirebaseFunctions
import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ReportClient")

public enum ReportType: String {
  case exhibition
  case photo
}

public struct ReportClient: Sendable {
  public var report:
    @Sendable (_ type: ReportType, _ id: String, _ reason: String) async throws -> Void
}

extension ReportClient {
  public static let liveValue = ReportClient(
    report: { type, id, reason in
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
        }
      )
    }
  )
}
