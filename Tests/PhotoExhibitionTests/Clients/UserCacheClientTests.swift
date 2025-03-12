import XCTest

@testable import PhotoExhibition

final class UserCacheClientTests: XCTestCase {
  var cacheClient: DefaultUserCacheClient!

  override func setUp() async throws {
    cacheClient = DefaultUserCacheClient()
  }

  override func tearDown() async throws {
    await cacheClient.clearCache()
    cacheClient = nil
  }

  func testSetAndGetUser() async {
    // Given
    let user = User(uid: "test-user-1")

    // When
    await cacheClient.setUser(user)
    let retrievedUser = await cacheClient.getUser(withUID: "test-user-1")

    // Then
    XCTAssertEqual(retrievedUser?.uid, user.uid)
  }

  func testGetUserWithUID() async {
    // Given
    let user1 = User(uid: "test-user-1")
    let user2 = User(uid: "test-user-2")

    // When
    await cacheClient.setUser(user1)
    await cacheClient.setUser(user2)

    // Then
    let retrievedUser1 = await cacheClient.getUser(withUID: "test-user-1")
    let retrievedUser2 = await cacheClient.getUser(withUID: "test-user-2")
    let nonExistentUser = await cacheClient.getUser(withUID: "non-existent")

    XCTAssertEqual(retrievedUser1?.uid, user1.uid)
    XCTAssertEqual(retrievedUser2?.uid, user2.uid)
    XCTAssertNil(nonExistentUser)
  }

  func testGetAllUsers() async {
    // Given
    let user1 = User(uid: "test-user-1")
    let user2 = User(uid: "test-user-2")
    let user3 = User(uid: "test-user-3")

    // When
    await cacheClient.setUser(user1)
    await cacheClient.setUser(user2)
    await cacheClient.setUser(user3)

    // Then
    let allUsers = await cacheClient.getAllUsers()
    XCTAssertEqual(allUsers.count, 3)
    XCTAssertTrue(allUsers.contains(where: { $0.uid == user1.uid }))
    XCTAssertTrue(allUsers.contains(where: { $0.uid == user2.uid }))
    XCTAssertTrue(allUsers.contains(where: { $0.uid == user3.uid }))
  }

  func testClearCache() async {
    // Given
    let user = User(uid: "test-user-1")
    await cacheClient.setUser(user)

    // When
    await cacheClient.clearCache()

    // Then
    let allUsers = await cacheClient.getAllUsers()
    XCTAssertTrue(allUsers.isEmpty)
  }

  func testMaxCacheSize() async {
    // Given - Create more users than the max cache size
    let maxSize = 100  // Default max size

    // When - Add more users than the max cache size
    for i in 1...maxSize + 10 {
      await cacheClient.setUser(User(uid: "test-user-\(i)"))
    }

    // Then - Cache should only contain max size users
    let allUsers = await cacheClient.getAllUsers()
    XCTAssertEqual(allUsers.count, maxSize)

    // The first 10 users should have been removed
    for i in 1...10 {
      let user = await cacheClient.getUser(withUID: "test-user-\(i)")
      XCTAssertNil(user)
    }

    // The last maxSize users should still be in the cache
    for i in 11...maxSize + 10 {
      let user = await cacheClient.getUser(withUID: "test-user-\(i)")
      XCTAssertNotNil(user)
    }
  }

  func testLRUEvictionPolicy() async {
    // Given
    await cacheClient.clearCache()  // Ensure we start with an empty cache

    // Create a smaller cache for testing LRU behavior more easily
    let smallCacheSize = 5
    cacheClient = DefaultUserCacheClient(maxCacheSize: smallCacheSize)

    // Add initial users to fill the cache
    for i in 1...smallCacheSize {
      await cacheClient.setUser(User(uid: "test-user-\(i)"))
    }

    // Access the first user to make it most recently used
    _ = await cacheClient.getUser(withUID: "test-user-1")

    // Add one more user to trigger eviction
    await cacheClient.setUser(User(uid: "test-user-\(smallCacheSize + 1)"))

    // Then
    // User1 should still be in cache because it was accessed recently
    let retrievedUser1 = await cacheClient.getUser(withUID: "test-user-1")
    XCTAssertNotNil(retrievedUser1, "User1 should be in cache as it was recently accessed")

    // User2 should be evicted because it was the least recently used
    let retrievedUser2 = await cacheClient.getUser(withUID: "test-user-2")
    XCTAssertNil(retrievedUser2, "User2 should be evicted as it was least recently used")

    // The newest user should be in the cache
    let retrievedUserNew = await cacheClient.getUser(withUID: "test-user-\(smallCacheSize + 1)")
    XCTAssertNotNil(retrievedUserNew, "Newly added user should be in the cache")
  }
}
