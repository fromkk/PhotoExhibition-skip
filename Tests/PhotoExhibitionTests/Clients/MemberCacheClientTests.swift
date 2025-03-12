import XCTest

@testable import PhotoExhibition

final class MemberCacheClientTests: XCTestCase {
  var cacheClient: DefaultMemberCacheClient!

  override func setUp() async throws {
    cacheClient = DefaultMemberCacheClient()
  }

  override func tearDown() async throws {
    await cacheClient.clearCache()
    cacheClient = nil
  }

  func testSetAndGetMember() async {
    // Given
    let member = createTestMember(id: "test-member-1")

    // When
    await cacheClient.setMember(member)
    let retrievedMember = await cacheClient.getMember(withID: "test-member-1")

    // Then
    XCTAssertEqual(retrievedMember?.id, member.id)
  }

  func testGetMemberWithID() async {
    // Given
    let member1 = createTestMember(id: "test-member-1")
    let member2 = createTestMember(id: "test-member-2")

    // When
    await cacheClient.setMember(member1)
    await cacheClient.setMember(member2)

    // Then
    let retrievedMember1 = await cacheClient.getMember(withID: "test-member-1")
    let retrievedMember2 = await cacheClient.getMember(withID: "test-member-2")
    let nonExistentMember = await cacheClient.getMember(withID: "non-existent")

    XCTAssertEqual(retrievedMember1?.id, member1.id)
    XCTAssertEqual(retrievedMember2?.id, member2.id)
    XCTAssertNil(nonExistentMember)
  }

  func testGetAllMembers() async {
    // Given
    let member1 = createTestMember(id: "test-member-1")
    let member2 = createTestMember(id: "test-member-2")
    let member3 = createTestMember(id: "test-member-3")

    // When
    await cacheClient.setMember(member1)
    await cacheClient.setMember(member2)
    await cacheClient.setMember(member3)

    // Then
    let allMembers = await cacheClient.getAllMembers()
    XCTAssertEqual(allMembers.count, 3)
    XCTAssertTrue(allMembers.contains(where: { $0.id == member1.id }))
    XCTAssertTrue(allMembers.contains(where: { $0.id == member2.id }))
    XCTAssertTrue(allMembers.contains(where: { $0.id == member3.id }))
  }

  func testClearCache() async {
    // Given
    let member = createTestMember(id: "test-member-1")
    await cacheClient.setMember(member)

    // When
    await cacheClient.clearCache()

    // Then
    let allMembers = await cacheClient.getAllMembers()
    XCTAssertTrue(allMembers.isEmpty)
  }

  func testMaxCacheSize() async {
    // Given - Create more members than the max cache size
    let maxSize = 100  // Default max size

    // When - Add more members than the max cache size
    for i in 1...maxSize + 10 {
      await cacheClient.setMember(createTestMember(id: "test-member-\(i)"))
    }

    // Then - Cache should only contain max size members
    let allMembers = await cacheClient.getAllMembers()
    XCTAssertEqual(allMembers.count, maxSize)

    // The first 10 members should have been removed
    for i in 1...10 {
      let member = await cacheClient.getMember(withID: "test-member-\(i)")
      XCTAssertNil(member)
    }

    // The last maxSize members should still be in the cache
    for i in 11...maxSize + 10 {
      let member = await cacheClient.getMember(withID: "test-member-\(i)")
      XCTAssertNotNil(member)
    }
  }

  func testLRUEvictionPolicy() async {
    // Given
    await cacheClient.clearCache()  // Ensure we start with an empty cache

    // Create a smaller cache for testing LRU behavior more easily
    let smallCacheSize = 5
    cacheClient = DefaultMemberCacheClient(maxCacheSize: smallCacheSize)

    // Add initial members to fill the cache
    for i in 1...smallCacheSize {
      await cacheClient.setMember(createTestMember(id: "test-member-\(i)"))
    }

    // Access the first member to make it most recently used
    _ = await cacheClient.getMember(withID: "test-member-1")

    // Add one more member to trigger eviction
    await cacheClient.setMember(createTestMember(id: "test-member-\(smallCacheSize + 1)"))

    // Then
    // Member1 should still be in cache because it was accessed recently
    let retrievedMember1 = await cacheClient.getMember(withID: "test-member-1")
    XCTAssertNotNil(retrievedMember1, "Member1 should be in cache as it was recently accessed")

    // Member2 should be evicted because it was the least recently used
    let retrievedMember2 = await cacheClient.getMember(withID: "test-member-2")
    XCTAssertNil(retrievedMember2, "Member2 should be evicted as it was least recently used")

    // The newest member should be in the cache
    let retrievedMemberNew = await cacheClient.getMember(
      withID: "test-member-\(smallCacheSize + 1)")
    XCTAssertNotNil(retrievedMemberNew, "Newly added member should be in the cache")
  }

  // Helper method to create test members
  private func createTestMember(id: String) -> Member {
    return Member(
      id: id,
      name: "Test Member \(id)",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )
  }
}
