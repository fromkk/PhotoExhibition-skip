import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class ReportStore: Store {
  enum Action {
    case reasonChanged(String)
    case sendButtonTapped
    case dismissButtonTapped
  }

  var reason: String = ""
  var isLoading: Bool = false
  var error: (any Error)?
  var isErrorAlertPresented: Bool = false
  var shouldDismiss: Bool = false

  private let reportClient: ReportClient
  private let type: ReportType
  private let id: String

  init(type: ReportType, id: String, reportClient: ReportClient = DefaultReportClient()) {
    self.type = type
    self.id = id
    self.reportClient = reportClient
  }

  func send(_ action: Action) {
    switch action {
    case .reasonChanged(let reason):
      self.reason = reason
    case .sendButtonTapped:
      Task {
        await sendReport()
      }
    case .dismissButtonTapped:
      shouldDismiss = true
    }
  }

  private func sendReport() async {
    isLoading = true
    await reportClient.report(type: type, id: id, reason: reason)
    shouldDismiss = true
    isLoading = false
  }
}
