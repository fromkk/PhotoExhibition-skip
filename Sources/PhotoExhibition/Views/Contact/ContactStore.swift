import PhotoExhibitionModel
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class ContactStore: Store {
  enum Action {
    case task
    case titleChanged(String)
    case contentChanged(String)
    case sendButtonTapped
  }

  var title: String = ""
  var content: String = ""
  var isLoading: Bool = false
  var shouldDismiss: Bool = false

  private let contactClient: any ContactClient
  private let analyticsClient: any AnalyticsClient

  init(
    contactClient: any ContactClient = DefaultContactClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.contactClient = contactClient
    self.analyticsClient = analyticsClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        await analyticsClient.analyticsScreen(name: "ContactView")
      }
    case .titleChanged(let title):
      self.title = title
    case .contentChanged(let content):
      self.content = content
    case .sendButtonTapped:
      Task {
        await sendContact()
      }
    }
  }

  private func sendContact() async {
    await contactClient.send(title: title, content: content)
    await analyticsClient.send(.contact, parameters: [:])
    shouldDismiss = true
  }
}
