import XCTest

@testable import PhotoExhibition

@MainActor
final class MockMembersClient: MembersClient {
  // MARK: - テスト用のプロパティ

  // fetch()の呼び出し追跡
  var fetchWasCalled: Bool = false
  var fetchArguments: [String] = []

  // モックデータ
  var mockMembers: [Member] = []
  var shouldSucceed: Bool = true
  var errorToThrow: Error?

  // MARK: - MembersClientプロトコルの実装

  func fetch(_ UIDs: [any Sendable]) async throws -> [Member] {
    fetchWasCalled = true
    fetchArguments = UIDs.map { $0 as! String }

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    // 指定されたUIDに一致するメンバーだけを返す
    return mockMembers.filter { member in
      UIDs.filter({ ($0 as! String) == member.id }).count > 0
    }
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    fetchWasCalled = false
    fetchArguments = []

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }

  func addMockMember(_ member: Member) {
    mockMembers.append(member)
  }
}
