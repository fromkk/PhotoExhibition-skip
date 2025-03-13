import XCTest

@testable import PhotoExhibition

@MainActor
final class MockMemberUpdateClient: MemberUpdateClient {
  // MARK: - テスト用のプロパティ

  // updateName()の呼び出し追跡
  var updateNameWasCalled: Bool = false
  var updatedMemberID: String? = nil
  var updatedName: String? = nil
  var updateNameExpectation = XCTestExpectation(description: "UpdateName method called")

  // モック結果
  var mockMember: Member = Member(
    id: "mock-user-id",
    name: "Mock User",
    icon: nil,
    createdAt: Date(),
    updatedAt: Date()
  )

  // 成功/失敗のシミュレーション
  var shouldSucceed: Bool = true
  var errorToThrow: Error? = nil

  // MARK: - MemberUpdateClientプロトコルの実装

  func updateName(memberID: String, name: String) async throws -> Member {
    updateNameWasCalled = true
    updatedMemberID = memberID
    updatedName = name
    updateNameExpectation.fulfill()

    if !shouldSucceed {
      if let error = errorToThrow {
        throw error
      } else {
        throw MemberUpdateClientError.updateFailed
      }
    }

    // 更新後のモックメンバーを返す
    return Member(
      id: memberID,
      name: name,
      icon: mockMember.icon,
      createdAt: mockMember.createdAt,
      updatedAt: Date()
    )
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    updateNameWasCalled = false
    updatedMemberID = nil
    updatedName = nil

    // 新しいExpectationを作成
    updateNameExpectation = XCTestExpectation(description: "UpdateName method called")

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
