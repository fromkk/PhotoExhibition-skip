import XCTest

@testable import PhotoExhibition

@MainActor
final class ContactStoreTests: XCTestCase {
  private var mockContactClient: MockContactClient!
  private var mockAnalyticsClient: MockAnalyticsClient!

  override func setUp() async throws {
    mockContactClient = MockContactClient()
    mockAnalyticsClient = MockAnalyticsClient()
  }

  override func tearDown() async throws {
    mockContactClient = nil
    mockAnalyticsClient = nil
  }

  func testInit() {
    // Arrange & Act
    let store = ContactStore(
      contactClient: mockContactClient,
      analyticsClient: mockAnalyticsClient
    )

    // Assert
    XCTAssertEqual(store.title, "")
    XCTAssertEqual(store.content, "")
    XCTAssertFalse(store.isLoading)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.isErrorAlertPresented)
    XCTAssertFalse(store.shouldDismiss)
  }

  func testTask() async throws {
    // Arrange
    let store = ContactStore(
      contactClient: mockContactClient,
      analyticsClient: mockAnalyticsClient
    )

    // Act
    store.send(ContactStore.Action.task)

    // Wait for the analytics to be called
    try await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertEqual(mockAnalyticsClient.screenCalls.count, 1)
    XCTAssertEqual(mockAnalyticsClient.screenCalls.first?.name, "ContactView")
  }

  func testTitleChanged() {
    // Arrange
    let store = ContactStore(
      contactClient: mockContactClient,
      analyticsClient: mockAnalyticsClient
    )

    // Act
    store.send(ContactStore.Action.titleChanged("New Title"))

    // Assert
    XCTAssertEqual(store.title, "New Title")
  }

  func testContentChanged() {
    // Arrange
    let store = ContactStore(
      contactClient: mockContactClient,
      analyticsClient: mockAnalyticsClient
    )

    // Act
    store.send(ContactStore.Action.contentChanged("New Content"))

    // Assert
    XCTAssertEqual(store.content, "New Content")
  }

  func testSendButtonTapped() async throws {
    // Arrange
    let store = ContactStore(
      contactClient: mockContactClient,
      analyticsClient: mockAnalyticsClient
    )

    store.title = "Test Title"
    store.content = "Test Content"

    // Act
    store.send(ContactStore.Action.sendButtonTapped)

    // Wait for the async operation to complete
    try await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertEqual(mockContactClient.sentTitles.count, 1)
    XCTAssertEqual(mockContactClient.sentTitles.first, "Test Title")
    XCTAssertEqual(mockContactClient.sentContents.count, 1)
    XCTAssertEqual(mockContactClient.sentContents.first, "Test Content")
    XCTAssertTrue(store.shouldDismiss)

    // Verify analytics was called
    XCTAssertEqual(mockAnalyticsClient.eventCalls.count, 1)
    XCTAssertEqual(mockAnalyticsClient.eventCalls.first?.event, .contact)
  }
}
