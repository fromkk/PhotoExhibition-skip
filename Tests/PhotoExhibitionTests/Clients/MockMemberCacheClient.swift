import XCTest

@testable import PhotoExhibition

@MainActor
final class MockMemberCacheClient: MemberCacheClient {
  // MARK: - テスト用のプロパティ

  // setMember()の呼び出し追跡
  var setMemberWasCalled: Bool = false
  var setMemberArgument: Member? = nil

  // getMember()の呼び出し追跡
  var getMemberWasCalled: Bool = false
  var getMemberID: String? = nil

  // getAllMembers()の呼び出し追跡
  var getAllMembersWasCalled: Bool = false

  // clearCache()の呼び出し追跡
  var clearCacheWasCalled: Bool = false

  // モックデータ
  var mockMembers: [String: Member] = [:]

  // MARK: - MemberCacheClientプロトコルの実装

  func setMember(_ member: Member) async {
    setMemberWasCalled = true
    setMemberArgument = member
    mockMembers[member.id] = member
  }

  func getMember(withID id: String) async -> Member? {
    getMemberWasCalled = true
    getMemberID = id
    return mockMembers[id]
  }

  func getAllMembers() async -> [Member] {
    getAllMembersWasCalled = true
    return Array(mockMembers.values)
  }

  func clearCache() async {
    clearCacheWasCalled = true
    mockMembers.removeAll()
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    setMemberWasCalled = false
    setMemberArgument = nil
    getMemberWasCalled = false
    getMemberID = nil
    getAllMembersWasCalled = false
    clearCacheWasCalled = false

    // モックデータをクリア
    mockMembers.removeAll()
  }

  // テスト用にメンバーを追加
  func addMockMember(_ member: Member) {
    mockMembers[member.id] = member
  }
}
