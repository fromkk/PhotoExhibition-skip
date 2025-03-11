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

  func testInit() {
    // Arrange & Act
    let mockCurrentUserClient = MockCurrentUserClient()
    let store = SettingsStore(currentUserClient: mockCurrentUserClient)

    // Assert
    XCTAssertFalse(store.isErrorAlertPresented)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.isLogoutConfirmationPresented)
  }

  func testLogoutSuccess() {
    // Arrange
    let mockCurrentUserClient = MockCurrentUserClient()
    let store = SettingsStore(currentUserClient: mockCurrentUserClient)
    let delegate = MockSettingsStoreDelegate()
    store.delegate = delegate

    // Act
    store.send(SettingsStore.Action.logoutButtonTapped)

    // Assert
    XCTAssertTrue(mockCurrentUserClient.logoutCalled)
    XCTAssertTrue(delegate.logoutCompletedCalled)
    XCTAssertFalse(store.isErrorAlertPresented)
    XCTAssertNil(store.error)
  }

  func testLogoutFailure() {
    // Arrange
    let mockCurrentUserClient = MockCurrentUserClient(shouldFailLogout: true)
    let store = SettingsStore(currentUserClient: mockCurrentUserClient)
    let delegate = MockSettingsStoreDelegate()
    store.delegate = delegate

    // Act
    store.send(SettingsStore.Action.logoutButtonTapped)

    // Assert
    XCTAssertTrue(mockCurrentUserClient.logoutCalled)
    XCTAssertFalse(delegate.logoutCompletedCalled)
    XCTAssertTrue(store.isErrorAlertPresented)
    XCTAssertNotNil(store.error)
  }

  func testPresentLogoutConfirmation() {
    // Arrange
    let store = SettingsStore()

    // Act
    store.send(SettingsStore.Action.presentLogoutConfirmation)

    // Assert
    XCTAssertTrue(store.isLogoutConfirmationPresented)
  }

  func testTask() {
    // Arrange
    let store = SettingsStore()

    // Act
    store.send(SettingsStore.Action.task)

    // Assert
    // taskアクションは何もしないので、特にアサーションはありません
    // ただし、クラッシュしないことを確認します
  }
}

// Mock classes for testing
final class MockCurrentUserClient: CurrentUserClient {
  var currentUserCalled = false
  var logoutCalled = false
  var shouldFailLogout: Bool
  var mockUser: User?

  init(shouldFailLogout: Bool = false, mockUser: User? = nil) {
    self.shouldFailLogout = shouldFailLogout
    self.mockUser = mockUser
  }

  func currentUser() -> User? {
    currentUserCalled = true
    return mockUser
  }

  func logout() throws {
    logoutCalled = true
    if shouldFailLogout {
      throw NSError(domain: "LogoutError", code: 1, userInfo: nil)
    }
  }
}

final class MockSettingsStoreDelegate: SettingsStoreDelegate, @unchecked Sendable {
  var logoutCompletedCalled = false

  func logoutCompleted() {
    logoutCompletedCalled = true
  }
}
