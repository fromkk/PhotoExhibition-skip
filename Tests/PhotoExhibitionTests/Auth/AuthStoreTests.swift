import Foundation
import XCTest

@testable import PhotoExhibition

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

@MainActor
final class AuthStoreTests: XCTestCase {

  func testInitWithSignInMode() {
    // Arrange & Act
    let store = AuthStore(authMode: AuthMode.signIn)

    // Assert
    XCTAssertEqual(store.authMode, .signIn)
    XCTAssertEqual(store.email, "")
    XCTAssertEqual(store.password, "")
    XCTAssertFalse(store.isLoading)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.isErrorAlertPresented)
  }

  func testInitWithSignUpMode() {
    // Arrange & Act
    let store = AuthStore(authMode: AuthMode.signUp)

    // Assert
    XCTAssertEqual(store.authMode, .signUp)
    XCTAssertEqual(store.email, "")
    XCTAssertEqual(store.password, "")
    XCTAssertFalse(store.isLoading)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.isErrorAlertPresented)
  }

  func testIsAuthEnabled() {
    // Arrange
    let store = AuthStore(authMode: AuthMode.signIn)

    // Act & Assert - 無効な状態
    store.email = "test"
    store.password = "pass"
    XCTAssertFalse(store.isAuthEnabled)

    // Act & Assert - 有効なメールアドレスだが短いパスワード
    store.email = "test@example.com"
    store.password = "pass"
    XCTAssertFalse(store.isAuthEnabled)

    // Act & Assert - 無効なメールアドレスだが長いパスワード
    store.email = "test"
    store.password = "password123"
    XCTAssertFalse(store.isAuthEnabled)

    // Act & Assert - 有効な状態
    store.email = "test@example.com"
    store.password = "password123"
    XCTAssertTrue(store.isAuthEnabled)
  }

  func testSignInSuccess() async throws {
    // Arrange
    let mockSignInClient = MockSignInClient()
    let store = AuthStore(
      authMode: AuthMode.signIn,
      signIngClient: mockSignInClient,
      signUpClient: MockSignUpClient()
    )
    let delegate = MockAuthStoreDelegate()
    store.delegate = delegate
    store.email = "test@example.com"
    store.password = "password123"

    // 初期状態を確認
    XCTAssertFalse(store.isLoading)

    // Act
    store.send(AuthStore.Action.signInButtonTapped)

    // isLoadingがtrueになることを確認
    XCTAssertTrue(store.isLoading)

    while store.isLoading {
      await Task.yield()
    }

    // 最終状態を確認
    XCTAssertFalse(store.isLoading)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.isErrorAlertPresented)
    XCTAssertTrue(delegate.didSignInSuccessfullyCalled)
    XCTAssertTrue(mockSignInClient.signInWasCalled)
    XCTAssertEqual(mockSignInClient.signInEmail, "test@example.com")
    XCTAssertEqual(mockSignInClient.signInPassword, "password123")
  }

  func testSignInFailure() async throws {
    // Arrange
    let mockSignInClient = MockSignInClient()
    mockSignInClient.shouldSucceed = false
    mockSignInClient.errorToThrow = NSError(domain: "SignInError", code: 1, userInfo: nil)

    let store = AuthStore(
      authMode: AuthMode.signIn,
      signIngClient: mockSignInClient,
      signUpClient: MockSignUpClient()
    )
    let delegate = MockAuthStoreDelegate()
    store.delegate = delegate
    store.email = "test@example.com"
    store.password = "password123"

    // 初期状態を確認
    XCTAssertFalse(store.isLoading)

    // Act
    store.send(AuthStore.Action.signInButtonTapped)

    // isLoadingがtrueになることを確認
    XCTAssertTrue(store.isLoading)

    while store.isLoading {
      await Task.yield()
    }

    // 最終状態を確認
    XCTAssertFalse(store.isLoading)
    XCTAssertNotNil(store.error)
    XCTAssertTrue(store.isErrorAlertPresented)
    XCTAssertFalse(delegate.didSignInSuccessfullyCalled)
    XCTAssertTrue(mockSignInClient.signInWasCalled)
  }

  func testSignUpSuccess() async throws {
    // Arrange
    let mockSignUpClient = MockSignUpClient()
    let store = AuthStore(
      authMode: AuthMode.signUp,
      signIngClient: MockSignInClient(),
      signUpClient: mockSignUpClient
    )
    let delegate = MockAuthStoreDelegate()
    store.delegate = delegate
    store.email = "test@example.com"
    store.password = "password123"

    // 初期状態を確認
    XCTAssertFalse(store.isLoading)

    // Act
    store.send(AuthStore.Action.signUpButtonTapped)

    // isLoadingがtrueになることを確認
    XCTAssertTrue(store.isLoading)

    while store.isLoading {
      await Task.yield()
    }

    // 最終状態を確認
    XCTAssertFalse(store.isLoading)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.isErrorAlertPresented)
    XCTAssertTrue(delegate.didSignInSuccessfullyCalled)
    XCTAssertTrue(mockSignUpClient.signUpWasCalled)
    XCTAssertEqual(mockSignUpClient.signUpEmail, "test@example.com")
    XCTAssertEqual(mockSignUpClient.signUpPassword, "password123")
  }

  func testSignUpFailure() async throws {
    // Arrange
    let mockSignUpClient = MockSignUpClient()
    mockSignUpClient.shouldSucceed = false
    mockSignUpClient.errorToThrow = NSError(domain: "SignUpError", code: 1, userInfo: nil)

    let store = AuthStore(
      authMode: AuthMode.signUp,
      signIngClient: MockSignInClient(),
      signUpClient: mockSignUpClient
    )
    let delegate = MockAuthStoreDelegate()
    store.delegate = delegate
    store.email = "test@example.com"
    store.password = "password123"

    // 初期状態を確認
    XCTAssertFalse(store.isLoading)

    // Act
    store.send(AuthStore.Action.signUpButtonTapped)

    // isLoadingがtrueになることを確認
    XCTAssertTrue(store.isLoading)

    while store.isLoading {
      await Task.yield()
    }

    // 最終状態を確認
    XCTAssertFalse(store.isLoading)
    XCTAssertNotNil(store.error)
    XCTAssertTrue(store.isErrorAlertPresented)
    XCTAssertFalse(delegate.didSignInSuccessfullyCalled)
    XCTAssertTrue(mockSignUpClient.signUpWasCalled)
  }

  func testDismissError() {
    // Arrange
    let store = AuthStore(authMode: AuthMode.signIn)
    store.error = NSError(domain: "test", code: 0, userInfo: nil)
    store.isErrorAlertPresented = true

    // Act
    store.send(AuthStore.Action.dismissError)

    // Assert
    XCTAssertFalse(store.isErrorAlertPresented)
  }
}

// Mock classes for testing
@MainActor
final class MockAuthStoreDelegate: AuthStoreDelegate {
  var didSignInSuccessfullyCalled = false
  var lastSignedInMember: Member?

  func didSignInSuccessfully(with member: Member) {
    didSignInSuccessfullyCalled = true
    lastSignedInMember = member
  }
}
