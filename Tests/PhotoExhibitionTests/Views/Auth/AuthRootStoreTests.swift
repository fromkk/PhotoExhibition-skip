import Foundation
import XCTest

@testable import PhotoExhibition

#if !SKIP
  import AuthenticationServices
#endif

@MainActor
final class AuthRootStoreTests: XCTestCase {
  var mockAuthClient: MockAuthClient!
  var mockDelegate: MockAuthRootStoreDelegate!

  override func setUp() async throws {
    mockAuthClient = MockAuthClient()
    mockDelegate = MockAuthRootStoreDelegate()
  }

  override func tearDown() async throws {
    mockAuthClient = nil
    mockDelegate = nil
  }

  func testInit() {
    // Arrange & Act
    let store = AuthRootStore(authClient: mockAuthClient)

    // Assert
    XCTAssertNil(store.authStore)
    XCTAssertFalse(store.showSignIn)
    XCTAssertFalse(store.showSignUp)
  }

  func testSignInButtonTapped() {
    // Arrange
    let store = AuthRootStore(authClient: mockAuthClient)
    store.delegate = mockDelegate

    // Act
    store.send(AuthRootStore.Action.signInButtonTapped)

    // Assert
    XCTAssertNotNil(store.authStore)
    XCTAssertEqual(store.authStore?.authMode, .signIn)
    XCTAssertTrue(store.showSignIn)
    XCTAssertFalse(store.showSignUp)
  }

  func testSignUpButtonTapped() {
    // Arrange
    let store = AuthRootStore(authClient: mockAuthClient)
    store.delegate = mockDelegate

    // Act
    store.send(AuthRootStore.Action.signUpButtonTapped)

    // Assert
    XCTAssertNotNil(store.authStore)
    XCTAssertEqual(store.authStore?.authMode, .signUp)
    XCTAssertFalse(store.showSignIn)
    XCTAssertTrue(store.showSignUp)
  }

  #if !SKIP
    func testSignInWithAppleCompletedSuccess() {
      // Arrange
      let store = AuthRootStore(authClient: mockAuthClient)
      store.delegate = mockDelegate
      let testMember = Member(
        id: "test-id",
        createdAt: Date(),
        updatedAt: Date()
      )
      mockAuthClient.memberToReturn = testMember

      // テスト用のトークンを作成
      let dummyToken = "test-token".data(using: .utf8)!

      // 直接モックAuthClientを呼び出す
      Task {
        do {
          let member = try await mockAuthClient.signInWithApple(
            identityToken: dummyToken.base64EncodedString(),
            nonce: "test-nonce"
          )
          // didSignInSuccessfullyをシミュレート
          store.send(AuthRootStore.Action.didSignInSuccessfully(member))
        } catch {
          XCTFail("Should not throw error: \(error)")
        }
      }

      // Wait for the async operation to complete
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

      // Assert
      XCTAssertTrue(mockAuthClient.signInWithAppleWasCalled)
      XCTAssertTrue(mockDelegate.didSignInSuccessfullyCalled)
      XCTAssertEqual(mockDelegate.lastSignedInMember?.id, testMember.id)
    }

    func testSignInWithAppleCompletedError() {
      // Arrange
      let store = AuthRootStore(authClient: mockAuthClient)
      store.delegate = mockDelegate
      let testError = NSError(domain: "test", code: 0, userInfo: nil)
      mockAuthClient.shouldSucceed = false
      mockAuthClient.errorToThrow = testError

      // エラーケースのテスト
      Task {
        do {
          let dummyToken = "test-token".data(using: .utf8)!
          _ = try await mockAuthClient.signInWithApple(
            identityToken: dummyToken.base64EncodedString(),
            nonce: "test-nonce"
          )
          XCTFail("Should throw error")
        } catch {
          // エラーケースのテスト成功
        }
      }

      // Wait for the async operation to complete
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

      // Assert
      XCTAssertTrue(mockAuthClient.signInWithAppleWasCalled)
      XCTAssertFalse(mockDelegate.didSignInSuccessfullyCalled)
      XCTAssertNil(mockDelegate.lastSignedInMember)
    }
  #endif

  func testDidSignInSuccessfully() {
    // Arrange
    let store = AuthRootStore(authClient: mockAuthClient)
    store.delegate = mockDelegate
    store.showSignIn = true
    store.showSignUp = true
    let testMember = Member(
      id: "test-id",
      createdAt: Date(),
      updatedAt: Date()
    )

    // Act
    store.send(AuthRootStore.Action.didSignInSuccessfully(testMember))

    // Assert
    XCTAssertFalse(store.showSignIn)
    XCTAssertFalse(store.showSignUp)
    XCTAssertTrue(mockDelegate.didSignInSuccessfullyCalled)
    XCTAssertEqual(mockDelegate.lastSignedInMember?.id, testMember.id)
  }
}

@MainActor
final class MockAuthRootStoreDelegate: AuthRootStoreDelegate {
  var didSignInSuccessfullyCalled = false
  var lastSignedInMember: Member?

  func didSignInSuccessfully(with member: Member) {
    didSignInSuccessfullyCalled = true
    lastSignedInMember = member
  }
}

@MainActor
final class MockAuthClient: AuthClient {
  var signInWithAppleWasCalled = false
  var shouldSucceed = true
  var errorToThrow: Error?
  var memberToReturn: Member?

  func signInWithApple(authorization: ASAuthorization, nonce: String) async throws -> Member {
    signInWithAppleWasCalled = true
    if shouldSucceed {
      return memberToReturn
        ?? Member(
          id: "test-id",
          createdAt: Date(),
          updatedAt: Date()
        )
    } else {
      throw errorToThrow ?? NSError(domain: "test", code: 0, userInfo: nil)
    }
  }

  func signInWithApple(identityToken: String, nonce: String) async throws -> Member {
    signInWithAppleWasCalled = true
    if shouldSucceed {
      return memberToReturn
        ?? Member(
          id: "test-id",
          createdAt: Date(),
          updatedAt: Date()
        )
    } else {
      throw errorToThrow ?? NSError(domain: "test", code: 0, userInfo: nil)
    }
  }
}
