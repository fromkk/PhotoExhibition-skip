import SwiftUI
import Viewer

@Observable final class ReportStore: Store, Hashable, Identifiable {
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

  private let reportClient: ReportClient
  private let type: ReportType
  let id: String

  init(
    type: ReportType,
    id: String,
    reportClient: ReportClient = .liveValue
  ) {
    self.type = type
    self.id = id
    self.reportClient = reportClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      // Initialize any necessary task
      break
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
    do {
      try await reportClient.report(type, id, reason)
      shouldDismiss = true
    } catch {
      self.error = error
      isErrorAlertPresented = true
    }
    isLoading = false
  }

  var hashValue: Int { id.hashValue }
  func hash(into hasher: inout Hasher) {
    hasher.combine(hashValue)
  }
  static func == (lhs: ReportStore, rhs: ReportStore) -> Bool {
    lhs.id == rhs.id
  }
}
