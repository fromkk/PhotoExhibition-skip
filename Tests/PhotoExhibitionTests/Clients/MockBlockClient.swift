import Foundation

@testable import PhotoExhibition

@MainActor
final class MockBlockClient: BlockClient {
  // MARK: - Test tracking properties

  var blockUserCalled = false
  var unblockUserCalled = false
  var isBlockedCalled = false
  var fetchBlockedUserIdsCalled = false

  var lastCurrentUserId: String?
  var lastBlockUserId: String?

  // MARK: - Mock responses

  var shouldSucceed = true
  var errorToThrow: Error?
  var isBlockedResult = false
  var blockedUserIds: [String] = []

  // MARK: - BlockClient implementation

  nonisolated func blockUser(currentUserId: String, blockUserId: String) async throws {
    await MainActor.run {
      blockUserCalled = true
      lastCurrentUserId = currentUserId
      lastBlockUserId = blockUserId
    }

    // 非同期処理をシミュレート
    await Task.yield()

    if await !shouldSucceed, let error = await errorToThrow {
      throw error
    }
  }

  nonisolated func unblockUser(currentUserId: String, blockUserId: String) async throws {
    await MainActor.run {
      unblockUserCalled = true
      lastCurrentUserId = currentUserId
      lastBlockUserId = blockUserId
    }

    // 非同期処理をシミュレート
    await Task.yield()

    if await !shouldSucceed, let error = await errorToThrow {
      throw error
    }
  }

  nonisolated func isBlocked(currentUserId: String, blockUserId: String) async throws -> Bool {
    await MainActor.run {
      isBlockedCalled = true
      lastCurrentUserId = currentUserId
      lastBlockUserId = blockUserId
    }

    // 非同期処理をシミュレート
    await Task.yield()

    if await !shouldSucceed, let error = await errorToThrow {
      throw error
    }

    return await isBlockedResult
  }

  nonisolated func fetchBlockedUserIds(currentUserId: String) async throws -> [String] {
    await MainActor.run {
      fetchBlockedUserIdsCalled = true
      lastCurrentUserId = currentUserId
    }

    // 非同期処理をシミュレート
    await Task.yield()

    if await !shouldSucceed, let error = await errorToThrow {
      throw error
    }

    return await blockedUserIds
  }

  // MARK: - Test helpers

  func reset() {
    blockUserCalled = false
    unblockUserCalled = false
    isBlockedCalled = false
    fetchBlockedUserIdsCalled = false
    lastCurrentUserId = nil
    lastBlockUserId = nil
    shouldSucceed = true
    errorToThrow = nil
    isBlockedResult = false
    blockedUserIds = []
  }
}
