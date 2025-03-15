import XCTest

@testable import PhotoExhibition

@MainActor
final class MockStorageClient: StorageClient {
  // MARK: - テスト用のプロパティ

  // url()の呼び出し追跡
  var urlWasCalled: Bool = false
  var urlPath: String? = nil
  var mockURL: URL = URL(string: "https://example.com/mock-image.jpg")!

  // upload()の呼び出し追跡
  var uploadWasCalled: Bool = false
  var uploadFromURL: URL? = nil
  var uploadToPath: String? = nil
  var mockUploadURL: URL = URL(string: "https://example.com/uploaded-image.jpg")!

  // delete()の呼び出し追跡
  var deleteWasCalled: Bool = false
  var deletePath: String? = nil

  // 成功/失敗のシミュレーション
  var shouldSucceed: Bool = true
  var errorToThrow: Error? = nil

  // MARK: - StorageClientプロトコルの実装

  func url(_ path: String) async throws -> URL {
    urlWasCalled = true
    urlPath = path

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    return mockURL
  }

  func upload(from url: URL, to path: String) async throws -> URL {
    uploadWasCalled = true
    uploadFromURL = url
    uploadToPath = path

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    return mockUploadURL
  }

  func delete(path: String) async throws {
    deleteWasCalled = true
    deletePath = path

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    urlWasCalled = false
    urlPath = nil
    uploadWasCalled = false
    uploadFromURL = nil
    uploadToPath = nil
    deleteWasCalled = false
    deletePath = nil

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
