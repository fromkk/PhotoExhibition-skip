import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class ContactStore: Store {
  enum Action {
    case titleChanged(String)
    case contentChanged(String)
    case sendButtonTapped
    case dismissButtonTapped
  }

  var title: String = ""
  var content: String = ""
  var isLoading: Bool = false
  var error: (any Error)?
  var isErrorAlertPresented: Bool = false
  var shouldDismiss: Bool = false

  private let contactClient: ContactClient

  init(contactClient: ContactClient = DefaultContactClient()) {
    self.contactClient = contactClient
  }

  func send(_ action: Action) {
    switch action {
    case .titleChanged(let title):
      self.title = title
    case .contentChanged(let content):
      self.content = content
    case .sendButtonTapped:
      Task {
        await sendContact()
      }
    case .dismissButtonTapped:
      shouldDismiss = true
    }
  }

  private func sendContact() async {
    isLoading = true
    do {
      try await contactClient.send(title: title, content: content)
      shouldDismiss = true
    } catch {
      self.error = error
      isErrorAlertPresented = true
    }
    isLoading = false
  }
}
