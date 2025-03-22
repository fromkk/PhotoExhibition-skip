import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class ReportStore: Store {
  enum Action {
    case task
    case reasonChanged(String)
    case sendButtonTapped
    case dismissButtonTapped
  }

  var reason: String = ""
  var isLoading: Bool = false
  var error: (any Error)?
  var isErrorAlertPresented: Bool = false
  var shouldDismiss: Bool = false

  private let reportClient: any ReportClient
  private let type: ReportType
  private let id: String
  private let analyticsClient: any AnalyticsClient

  init(
    type: ReportType,
    id: String,
    reportClient: any ReportClient = DefaultReportClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.type = type
    self.id = id
    self.reportClient = reportClient
    self.analyticsClient = analyticsClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        await analyticsClient.analyticsScreen(name: "ReportView")
      }
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
