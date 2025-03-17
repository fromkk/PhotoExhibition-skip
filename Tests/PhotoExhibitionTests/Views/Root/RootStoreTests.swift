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
  var mockCurrentUserClient: MockCurrentUserClient!
  var mockMembersClient: MockMembersClient!

  override func setUp() async throws {
    mockCurrentUserClient = MockCurrentUserClient()
    mockMembersClient = MockMembersClient()
  }

  override func tearDown() async throws {
    mockCurrentUserClient = nil
    mockMembersClient = nil
  }

  func testInit() {
    // Arrange & Act
    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Assert
    XCTAssertFalse(store.isSignedIn)
    XCTAssertFalse(store.isSignInScreenShown)
    XCTAssertFalse(store.isSignUpScreenShown)
    XCTAssertNil(store.authStore)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
  }

  func testTaskWithNoUser() async {
    // Arrange
    mockCurrentUserClient.mockUser = nil
    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(RootStore.Action.task)

    // 非同期処理が完了するのを待つ
    await Task.yield()

    // Assert
    XCTAssertFalse(store.isSignedIn)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
    XCTAssertFalse(mockMembersClient.fetchWasCalled)
  }

  func testTaskWithUserAndMember() async {
    // Arrange
    let userID = "test-uid"
    let testMember = Member(
      id: userID,
      name: "Test User",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    mockCurrentUserClient.mockUser = User(uid: userID)
    mockMembersClient.addMockMember(testMember)

    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(RootStore.Action.task)

    // 非同期処理が完了するのを待つ
    await Task.yield()

    // Assert
    XCTAssertTrue(mockMembersClient.fetchWasCalled)
    XCTAssertEqual(mockMembersClient.fetchArguments, [userID])
    XCTAssertTrue(store.isSignedIn)
    XCTAssertNotNil(store.exhibitionsStore)
    XCTAssertNotNil(store.settingsStore)
    XCTAssertFalse(store.isProfileSetupShown)
  }

  func testTaskWithUserAndMemberWithoutName() async {
    // Arrange
    let userID = "test-uid"
    let testMember = Member(
      id: userID,
      name: nil,  // 名前なし
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    mockCurrentUserClient.mockUser = User(uid: userID)
    mockMembersClient.addMockMember(testMember)

    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(RootStore.Action.task)

    // 非同期処理が完了するのを待つ
    await Task.yield()

    // Assert
    XCTAssertTrue(mockMembersClient.fetchWasCalled)
    XCTAssertTrue(store.isSignedIn)
    XCTAssertTrue(store.isProfileSetupShown)
    XCTAssertNotNil(store.profileSetupStore)
  }

  func testTaskWithUserButNoMember() async {
    // Arrange
    mockCurrentUserClient.mockUser = User(uid: "test-uid")
    // メンバーは追加しない

    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(RootStore.Action.task)

    // 非同期処理が完了するのを待つ
    await Task.yield()

    // Assert
    XCTAssertTrue(mockMembersClient.fetchWasCalled)
    XCTAssertFalse(store.isSignedIn)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
  }

  func testTaskWithUserButFetchError() async {
    // Arrange
    mockCurrentUserClient.mockUser = User(uid: "test-uid")
    mockMembersClient.shouldSucceed = false
    mockMembersClient.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: nil)

    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(RootStore.Action.task)

    // 非同期処理が完了するのを待つ
    await Task.yield()

    // Assert
    XCTAssertTrue(mockMembersClient.fetchWasCalled)
    XCTAssertFalse(store.isSignedIn)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
  }

  func testSignInButtonTapped() {
    // Arrange
    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(RootStore.Action.signInButtonTapped)

    // Assert
    XCTAssertTrue(store.isSignInScreenShown)
    XCTAssertNotNil(store.authStore)
    XCTAssertEqual(store.authStore?.authMode, AuthMode.signIn)
  }

  func testSignUpButtonTapped() {
    // Arrange
    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(RootStore.Action.signUpButtonTapped)

    // Assert
    XCTAssertTrue(store.isSignUpScreenShown)
    XCTAssertNotNil(store.authStore)
    XCTAssertEqual(store.authStore?.authMode, AuthMode.signUp)
  }

  func testDidSignInSuccessfully() {
    // Arrange
    let testMember = Member(
      id: "test-uid",
      name: "Test User",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.didSignInSuccessfully(with: testMember)

    // Assert
    XCTAssertTrue(store.isSignedIn)
    XCTAssertNotNil(store.exhibitionsStore)
    XCTAssertNotNil(store.settingsStore)
    XCTAssertFalse(store.isProfileSetupShown)
  }

  func testDidSignInSuccessfullyWithoutName() {
    // Arrange
    let testMember = Member(
      id: "test-uid",
      name: nil,
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.didSignInSuccessfully(with: testMember)

    // Assert
    XCTAssertTrue(store.isSignedIn)
    XCTAssertNotNil(store.exhibitionsStore)
    XCTAssertNotNil(store.settingsStore)
    XCTAssertTrue(store.isProfileSetupShown)
    XCTAssertNotNil(store.profileSetupStore)
  }

  func testLogoutCompleted() {
    // Arrange
    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )
    let testMember = Member(
      id: "test-uid",
      name: "Test User",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )
    store.didSignInSuccessfully(with: testMember)

    // 事前条件の確認
    XCTAssertTrue(store.isSignedIn)

    // Act
    store.logoutCompleted()

    // Assert
    XCTAssertFalse(store.isSignedIn)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
  }

  func testDidCompleteProfileSetup() {
    // Arrange
    let testMember = Member(
      id: "test-uid",
      name: nil,
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    let store = RootStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )
    store.didSignInSuccessfully(with: testMember)

    // Act
    store.didCompleteProfileSetup()

    // Assert
    XCTAssertFalse(store.isProfileSetupShown)
    XCTAssertNil(store.profileSetupStore)
  }
}
