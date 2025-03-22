import Foundation
import XCTest

@testable import PhotoExhibition

#if SKIP
  import SkipFirebaseAuth
#else
  import FirebaseAuth
#endif

@MainActor
final class SettingsStoreTests: XCTestCase {
  var mockCurrentUserClient: MockCurrentUserClient!
  var mockMembersClient: MockMembersClient!
  var mockAnalyticsClient: MockAnalyticsClient!

  override func setUp() async throws {
    mockCurrentUserClient = MockCurrentUserClient()
    mockMembersClient = MockMembersClient()
    mockAnalyticsClient = MockAnalyticsClient()
  }

  override func tearDown() async throws {
    mockCurrentUserClient = nil
    mockMembersClient = nil
    mockAnalyticsClient = nil
  }

  func testInit() {
    // Arrange & Act
    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Assert
    XCTAssertFalse(store.isErrorAlertPresented)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.isLogoutConfirmationPresented)
    XCTAssertNil(store.member)
    XCTAssertFalse(store.isProfileEditPresented)
  }

  func testLogoutSuccess() {
    // Arrange
    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )
    let delegate = MockSettingsStoreDelegate()
    store.delegate = delegate

    // Act
    store.send(SettingsStore.Action.logoutButtonTapped)

    // Assert
    XCTAssertTrue(mockCurrentUserClient.logoutWasCalled)
    XCTAssertTrue(delegate.logoutCompletedCalled)
    XCTAssertFalse(store.isErrorAlertPresented)
    XCTAssertNil(store.error)
  }

  func testLogoutFailure() {
    // Arrange
    mockCurrentUserClient.shouldSucceed = false
    mockCurrentUserClient.errorToThrow = NSError(domain: "LogoutError", code: 1, userInfo: nil)

    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )
    let delegate = MockSettingsStoreDelegate()
    store.delegate = delegate

    // Act
    store.send(SettingsStore.Action.logoutButtonTapped)

    // Assert
    XCTAssertTrue(mockCurrentUserClient.logoutWasCalled)
    XCTAssertFalse(delegate.logoutCompletedCalled)
    XCTAssertTrue(store.isErrorAlertPresented)
    XCTAssertNotNil(store.error)
  }

  func testPresentLogoutConfirmation() {
    // Arrange
    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(SettingsStore.Action.presentLogoutConfirmation)

    // Assert
    XCTAssertTrue(store.isLogoutConfirmationPresented)
  }

  func testTask() async {
    // Arrange
    let userId = "test-user-id"
    let testMember = Member(
      id: userId,
      name: "Test User",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    mockCurrentUserClient.mockUser = User(uid: userId)
    mockMembersClient.addMockMember(testMember)

    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(SettingsStore.Action.task)

    // 非同期処理が完了するのを待つ
    await Task.yield()

    // Assert
    XCTAssertTrue(mockMembersClient.fetchWasCalled)
    XCTAssertEqual(mockMembersClient.fetchArguments.first, userId)
    XCTAssertEqual(store.member?.id, testMember.id)
    XCTAssertEqual(store.member?.name, testMember.name)
  }

  func testEditProfileButtonTapped() {
    // Arrange
    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(SettingsStore.Action.editProfileButtonTapped)

    // Assert
    XCTAssertTrue(store.isProfileEditPresented)
  }

  func testDidCompleteProfileSetup() async {
    // Arrange
    let userId = "test-user-id"
    let testMember = Member(
      id: userId,
      name: "Test User",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    mockCurrentUserClient.mockUser = User(uid: userId)
    mockMembersClient.addMockMember(testMember)

    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.didCompleteProfileSetup()

    // 非同期処理が完了するのを待つ
    await Task.yield()

    // Assert
    XCTAssertFalse(store.isProfileEditPresented)
    XCTAssertTrue(mockMembersClient.fetchWasCalled)
  }

  func testPresentDeleteAccountConfirmation() {
    // Arrange
    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(SettingsStore.Action.presentDeleteAccountConfirmation)

    // Assert
    XCTAssertTrue(store.isDeleteAccountConfirmationPresented)
  }

  func testDeleteAccountSuccess() async {
    // Arrange
    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )
    let delegate = MockSettingsStoreDelegate()
    store.delegate = delegate

    // Act
    store.send(SettingsStore.Action.deleteAccountButtonTapped)

    // 非同期処理が完了するのを待つ
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // Assert
    XCTAssertTrue(mockCurrentUserClient.deleteAccountWasCalled)
    XCTAssertTrue(delegate.deleteAccountCompletedCalled)
    XCTAssertFalse(store.isErrorAlertPresented)
    XCTAssertNil(store.error)
  }

  func testDeleteAccountFailure() async {
    // Arrange
    mockCurrentUserClient.shouldSucceed = false
    mockCurrentUserClient.errorToThrow = NSError(
      domain: "DeleteAccountError", code: 1, userInfo: nil)

    let store = SettingsStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )
    let delegate = MockSettingsStoreDelegate()
    store.delegate = delegate

    // Act
    store.send(SettingsStore.Action.deleteAccountButtonTapped)

    // 非同期処理が完了するのを待つ
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // Assert
    XCTAssertTrue(mockCurrentUserClient.deleteAccountWasCalled)
    XCTAssertFalse(delegate.deleteAccountCompletedCalled)
    XCTAssertTrue(store.isErrorAlertPresented)
    XCTAssertNotNil(store.error)
  }
}

// Mock classes for testing
@MainActor
final class MockSettingsStoreDelegate: SettingsStoreDelegate {
  var logoutCompletedCalled = false
  var deleteAccountCompletedCalled = false

  func logoutCompleted() {
    logoutCompletedCalled = true
  }

  func deleteAccountCompleted() {
    deleteAccountCompletedCalled = true
  }
}
