import Observation
import SwiftUI
import Viewer

@Observable final class ContactStore: Store, @preconcurrency Hashable {
  let id: UUID = UUID()

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

  init(
    contactClient: any ContactClient = DefaultContactClient()
  ) {
    self.contactClient = contactClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      break
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

  var hashValue: Int { id.hashValue }
  func hash(into hasher: inout Hasher) {
    hasher.combine(hashValue)
  }
  static func == (lhs: ContactStore, rhs: ContactStore) -> Bool {
    lhs.id == rhs.id
  }
}
