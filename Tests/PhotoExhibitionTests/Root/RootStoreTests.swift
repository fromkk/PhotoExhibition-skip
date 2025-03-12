import Foundation
import XCTest

@testable import PhotoExhibition

#if SKIP
  import SkipFirebaseAuth
#else
  import FirebaseAuth
#endif

@MainActor
final class RootStoreTests: XCTestCase {

  func testInit() {
    // Arrange & Act
    let mockCurrentUserClient = MockCurrentUserClient()
    let store = RootStore(currentUserClient: mockCurrentUserClient)

    // Assert
    XCTAssertFalse(store.isSignedIn)
    XCTAssertFalse(store.isSignInScreenShown)
    XCTAssertFalse(store.isSignUpScreenShown)
    XCTAssertNil(store.authStore)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
  }

  func testTaskWithNoUser() {
    // Arrange
    let mockCurrentUserClient = MockCurrentUserClient(mockUser: nil)
    let store = RootStore(currentUserClient: mockCurrentUserClient)

    // Act
    store.send(RootStore.Action.task)

    // Assert
    XCTAssertTrue(mockCurrentUserClient.currentUserCalled)
    XCTAssertFalse(store.isSignedIn)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
  }

  func testTaskWithUser() {
    // Arrange
    let mockUser = PhotoExhibition.User(uid: "test-uid")
    let mockCurrentUserClient = MockCurrentUserClient(mockUser: mockUser)
    let store = RootStore(currentUserClient: mockCurrentUserClient)

    // Act
    store.send(RootStore.Action.task)

    // Assert
    XCTAssertTrue(mockCurrentUserClient.currentUserCalled)
    XCTAssertTrue(store.isSignedIn)
    XCTAssertNotNil(store.exhibitionsStore)
    XCTAssertNotNil(store.settingsStore)
  }

  func testSignInButtonTapped() {
    // Arrange
    let store = RootStore()

    // Act
    store.send(RootStore.Action.signInButtonTapped)

    // Assert
    XCTAssertTrue(store.isSignInScreenShown)
    XCTAssertNotNil(store.authStore)
    XCTAssertEqual(store.authStore?.authMode, AuthMode.signIn)
  }

  func testSignUpButtonTapped() {
    // Arrange
    let store = RootStore()

    // Act
    store.send(RootStore.Action.signUpButtonTapped)

    // Assert
    XCTAssertTrue(store.isSignUpScreenShown)
    XCTAssertNotNil(store.authStore)
    XCTAssertEqual(store.authStore?.authMode, AuthMode.signUp)
  }

  func testDidSignInSuccessfully() {
    // Arrange
    let store = RootStore()

    // Act
    store.didSignInSuccessfully()

    // Assert
    XCTAssertTrue(store.isSignedIn)
    XCTAssertNotNil(store.exhibitionsStore)
    XCTAssertNotNil(store.settingsStore)
  }

  func testLogoutCompleted() {
    // Arrange
    let store = RootStore()
    store.didSignInSuccessfully()  // サインイン状態にする

    // Act
    store.logoutCompleted()

    // Assert
    XCTAssertFalse(store.isSignedIn)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
  }

  func testIsSignedInDidSet() {
    // Arrange
    let store = RootStore()

    // Act
    store.didSignInSuccessfully()  // isSignedInをtrueに設定

    // Assert - サインイン時
    XCTAssertTrue(store.isSignedIn)
    XCTAssertNotNil(store.exhibitionsStore)
    XCTAssertNotNil(store.settingsStore)
    XCTAssertNotNil(store.settingsStore?.delegate)

    // Act
    store.logoutCompleted()  // isSignedInをfalseに設定

    // Assert - サインアウト時
    XCTAssertFalse(store.isSignedIn)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
  }

  func testIsSignInScreenShownDidSet() {
    // Arrange
    let store = RootStore()

    // Act - 表示
    store.isSignInScreenShown = true

    // Assert - 表示時
    XCTAssertNotNil(store.authStore)
    XCTAssertEqual(store.authStore?.authMode, AuthMode.signIn)
    XCTAssertNotNil(store.authStore?.delegate)

    // Act - 非表示
    store.isSignInScreenShown = false

    // Assert - 非表示時
    XCTAssertNil(store.authStore)
  }

  func testIsSignUpScreenShownDidSet() {
    // Arrange
    let store = RootStore()

    // Act - 表示
    store.isSignUpScreenShown = true

    // Assert - 表示時
    XCTAssertNotNil(store.authStore)
    XCTAssertEqual(store.authStore?.authMode, AuthMode.signUp)
    XCTAssertNotNil(store.authStore?.delegate)

    // Act - 非表示
    store.isSignUpScreenShown = false

    // Assert - 非表示時
    XCTAssertNil(store.authStore)
  }
}
