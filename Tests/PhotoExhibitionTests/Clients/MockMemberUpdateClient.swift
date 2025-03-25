import XCTest

@testable import PhotoExhibition

@MainActor
final class MockMemberUpdateClient: MemberUpdateClient {
  // MARK: - テスト用のプロパティ

  // updateName()の呼び出し追跡
  var updateNameWasCalled: Bool = false
  var updatedMemberID: String? = nil
  var updatedName: String? = nil

  // updateIcon()の呼び出し追跡
  var updateIconWasCalled: Bool = false
  var updatedIconMemberID: String? = nil
  var updatedIconPath: String? = nil

  // updateProfile()の呼び出し追跡
  var updateProfileWasCalled: Bool = false
  var updatedProfileMemberID: String? = nil
  var updatedProfileName: String? = nil
  var updatedProfileIconPath: String? = nil

  // postAgreement()の呼び出し追跡
  var postAgreementCalled = false
  var postAgreementMemberID: String?
  var postAgreementResult: Member?
  var postAgreementError: Error?

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

    // 非同期処理をシミュレート
    await Task.yield()

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

  func updateIcon(memberID: String, iconPath: String?) async throws -> Member {
    updateIconWasCalled = true
    updatedIconMemberID = memberID
    updatedIconPath = iconPath

    // 非同期処理をシミュレート
    await Task.yield()

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
      name: mockMember.name,
      icon: iconPath,
      createdAt: mockMember.createdAt,
      updatedAt: Date()
    )
  }

  func updateProfile(memberID: String, name: String, iconPath: String?) async throws -> Member {
    updateProfileWasCalled = true
    updatedProfileMemberID = memberID
    updatedProfileName = name
    updatedProfileIconPath = iconPath

    // 非同期処理をシミュレート
    await Task.yield()

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
      icon: iconPath,
      createdAt: mockMember.createdAt,
      updatedAt: Date()
    )
  }

  func postAgreement(memberID: String) async throws -> Member {
    postAgreementCalled = true
    postAgreementMemberID = memberID

    if let error = postAgreementError {
      throw error
    }

    return postAgreementResult
      ?? Member(
        id: memberID,
        name: "Test User",
        icon: nil,
        postAgreement: true,
        createdAt: Date(),
        updatedAt: Date()
      )
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    updateNameWasCalled = false
    updatedMemberID = nil
    updatedName = nil
    updateIconWasCalled = false
    updatedIconMemberID = nil
    updatedIconPath = nil
    updateProfileWasCalled = false
    updatedProfileMemberID = nil
    updatedProfileName = nil
    updatedProfileIconPath = nil
    postAgreementCalled = false
    postAgreementMemberID = nil
    postAgreementResult = nil
    postAgreementError = nil

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
