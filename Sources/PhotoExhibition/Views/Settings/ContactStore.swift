import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable final class ContactStore: Store {
  enum Action {
    case titleChanged(String)
    case contentChanged(String)
    case sendButtonTapped
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
    }
  }

  private func sendContact() async {
    await contactClient.send(title: title, content: content)
    shouldDismiss = true
  }
}
