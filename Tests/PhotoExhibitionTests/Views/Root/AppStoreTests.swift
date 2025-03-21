import Foundation
import XCTest

@testable import PhotoExhibition

@MainActor
final class AppStoreTests: XCTestCase {
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
    let store = AppStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Assert
    XCTAssertFalse(store.isSignedIn)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
  }

  func testTaskWithNoUser() async {
    // Arrange
    mockCurrentUserClient.mockUser = nil
    let store = AppStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(AppStore.Action.task)

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

    let store = AppStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(AppStore.Action.task)

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

    let store = AppStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(AppStore.Action.task)

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

    let store = AppStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(AppStore.Action.task)

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

    let store = AppStore(
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )

    // Act
    store.send(AppStore.Action.task)

    // 非同期処理が完了するのを待つ
    await Task.yield()

    // Assert
    XCTAssertTrue(mockMembersClient.fetchWasCalled)
    XCTAssertFalse(store.isSignedIn)
    XCTAssertNil(store.exhibitionsStore)
    XCTAssertNil(store.settingsStore)
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

    let store = AppStore(
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

    let store = AppStore(
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
}
