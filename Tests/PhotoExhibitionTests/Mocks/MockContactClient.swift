@testable import PhotoExhibition

@MainActor
final class MockContactClient: ContactClient {
  private(set) var sentTitles: [String] = []
  private(set) var sentContents: [String] = []

  func send(title: String, content: String) async {
    sentTitles.append(title)
    sentContents.append(content)
  }
}
