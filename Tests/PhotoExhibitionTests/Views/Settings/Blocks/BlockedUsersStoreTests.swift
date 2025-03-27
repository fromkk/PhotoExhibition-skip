import XCTest

@testable import PhotoExhibition

@MainActor
final class BlockedUsersStoreTests: XCTestCase {
  var store: BlockedUsersStore!
  var mockBlockClient: MockBlockClient!
  var mockCurrentUserClient: MockCurrentUserClient!
  var mockMembersClient: MockMembersClient!

  override func setUp() async throws {
    mockBlockClient = MockBlockClient()
    mockCurrentUserClient = MockCurrentUserClient()
    mockMembersClient = MockMembersClient()

    // Set up test user information
    mockCurrentUserClient.mockUser = User(uid: "testUser")

    store = BlockedUsersStore(
      blockClient: mockBlockClient,
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient
    )
  }

  override func tearDown() async throws {
    store = nil
    mockBlockClient = nil
    mockCurrentUserClient = nil
    mockMembersClient = nil
  }

  func testLoadBlockedUsers() async throws {
    // Set up test data
    mockBlockClient.blockedUserIds = ["user1", "user2"]

    let testMembers = [
      Member(id: "user1", name: "User One", createdAt: Date(), updatedAt: Date()),
      Member(id: "user2", name: "User Two", createdAt: Date(), updatedAt: Date()),
    ]

    for member in testMembers {
      try await mockMembersClient.addMockMember(member)
    }

    // Load blocked users
    store.send(BlockedUsersStore.Action.task)

    // Wait for async operations to complete
    #if !SKIP
      try await Task.sleep(nanoseconds: 1_000_000)  // Wait 1ms
    #endif

    // Verify
    XCTAssertTrue(mockBlockClient.fetchBlockedUserIdsCalled)
    XCTAssertEqual(mockBlockClient.lastCurrentUserId, "testUser")
    XCTAssertTrue(mockMembersClient.fetchWasCalled)
    XCTAssertEqual(mockMembersClient.fetchArguments, ["user1", "user2"])
    XCTAssertEqual(store.blockedUsers.count, 2)
    XCTAssertEqual(store.blockedUsers[0].id, "user1")
    XCTAssertEqual(store.blockedUsers[1].id, "user2")
    XCTAssertFalse(store.isLoading)
  }

  func testUnblockUser() async throws {
    // Add users to block list beforehand
    let testMembers = [
      Member(id: "user1", name: "User One", createdAt: Date(), updatedAt: Date()),
      Member(id: "user2", name: "User Two", createdAt: Date(), updatedAt: Date()),
    ]
    store.blockedUsers = testMembers

    // Unblock a user
    store.send(BlockedUsersStore.Action.unblockButtonTapped("user1"))

    // Wait for async operations to complete
    try await Task.sleep(nanoseconds: 1_000_000)  // Wait 1ms

    // Verify
    XCTAssertTrue(mockBlockClient.unblockUserCalled)
    XCTAssertEqual(mockBlockClient.lastCurrentUserId, "testUser")
    XCTAssertEqual(mockBlockClient.lastBlockUserId, "user1")

    // Verify the user was removed from the list
    XCTAssertEqual(store.blockedUsers.count, 1)
    XCTAssertEqual(store.blockedUsers[0].id, "user2")
  }

  func testErrorHandling() async throws {
    // Simulate an error
    mockBlockClient.shouldSucceed = false
    mockBlockClient.errorToThrow = NSError(
      domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

    // Load blocked users
    store.send(BlockedUsersStore.Action.task)

    // Wait for async operations to complete
    try await Task.sleep(nanoseconds: 1_000_000)  // Wait 1ms

    // Verify
    XCTAssertTrue(mockBlockClient.fetchBlockedUserIdsCalled)
    XCTAssertTrue(store.showErrorAlert)
    XCTAssertNotNil(store.error)
    XCTAssertFalse(store.isLoading)
    XCTAssertEqual(store.blockedUsers.count, 0)
  }
}
