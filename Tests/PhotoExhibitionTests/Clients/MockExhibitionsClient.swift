import XCTest

@testable import PhotoExhibition

@MainActor
final class MockExhibitionsClient: ExhibitionsClient {
  // MARK: - テスト用のプロパティ

  // fetch()のモック結果
  var mockExhibitions: [Exhibition] = []
  var mockNextCursor: String? = nil

  // delete()の呼び出し追跡
  var deleteWasCalled: Bool = false
  var deletedExhibitionId: String? = nil

  // create()の呼び出し追跡
  var createWasCalled: Bool = false
  var createdData: [String: any Sendable]? = nil
  var mockCreatedId: String = "mock-created-id"

  // create(id:data:)の呼び出し追跡
  var createWithIdWasCalled: Bool = false
  var createdWithId: String? = nil
  var createdWithIdData: [String: any Sendable]? = nil

  // update()の呼び出し追跡
  var updateWasCalled: Bool = false
  var updatedId: String? = nil
  var updatedData: [String: any Sendable]? = nil

  // get()の呼び出し追跡
  var getWasCalled: Bool = false
  var getExhibitionId: String? = nil
  var mockExhibition: Exhibition? = nil

  // fetchMyExhibitions()の呼び出し追跡
  var fetchMyExhibitionsWasCalled: Bool = false
  var fetchMyExhibitionsOrganizerID: String? = nil
  var fetchMyExhibitionsCursor: String? = nil

  // 成功/失敗のシミュレーション
  var shouldSucceed: Bool = true
  var errorToThrow: Error? = nil

  // カスタムコールバック
  var updateCallback: ((String, [String: any Sendable]) -> Void)? = nil

  // MARK: - ExhibitionsClientプロトコルの実装

  func fetch(now: Date, cursor: String?) async throws -> (
    exhibitions: [Exhibition], nextCursor: String?
  ) {
    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
    return (mockExhibitions, mockNextCursor)
  }

  func create(data: [String: any Sendable]) async throws -> String {
    createWasCalled = true
    createdData = data

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    return mockCreatedId
  }

  func create(id: String, data: [String: any Sendable]) async throws {
    createWithIdWasCalled = true
    createdWithId = id
    createdWithIdData = data

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
  }

  func update(id: String, data: [String: any Sendable]) async throws {
    updateWasCalled = true
    updatedId = id
    updatedData = data

    // カスタムコールバックを実行
    updateCallback?(id, data)

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
  }

  func delete(id: String) async throws {
    deleteWasCalled = true
    deletedExhibitionId = id

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
  }

  func get(id: String) async throws -> Exhibition {
    getWasCalled = true
    getExhibitionId = id

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    guard let exhibition = mockExhibition else {
      throw NSError(
        domain: "MockExhibitionsClient", code: 404,
        userInfo: [
          NSLocalizedDescriptionKey: "Mock exhibition not found"
        ])
    }

    return exhibition
  }

  func fetchMyExhibitions(organizerID: String, cursor: String?) async throws -> (
    exhibitions: [Exhibition], nextCursor: String?
  ) {
    fetchMyExhibitionsWasCalled = true
    fetchMyExhibitionsOrganizerID = organizerID
    fetchMyExhibitionsCursor = cursor

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    return (mockExhibitions, mockNextCursor)
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    deleteWasCalled = false
    deletedExhibitionId = nil
    createWasCalled = false
    createdData = nil
    createWithIdWasCalled = false
    createdWithId = nil
    createdWithIdData = nil
    updateWasCalled = false
    updatedId = nil
    updatedData = nil
    getWasCalled = false
    getExhibitionId = nil
    fetchMyExhibitionsWasCalled = false
    fetchMyExhibitionsOrganizerID = nil
    fetchMyExhibitionsCursor = nil

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
