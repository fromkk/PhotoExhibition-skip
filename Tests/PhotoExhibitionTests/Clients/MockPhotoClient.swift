import XCTest

@testable import PhotoExhibition

@MainActor
final class MockPhotoClient: PhotoClient {
  // MARK: - テスト用のプロパティ

  // fetchPhotos()の呼び出し追跡
  var fetchPhotosWasCalled: Bool = false
  var fetchPhotosExhibitionId: String? = nil
  var mockPhotos: [Photo] = []

  // addPhoto()の呼び出し追跡
  var addPhotoWasCalled: Bool = false
  var addPhotoExhibitionId: String? = nil
  var addPhotoPath: String? = nil
  var mockAddedPhoto: Photo? = nil

  // deletePhoto()の呼び出し追跡
  var deletePhotoWasCalled: Bool = false
  var deletePhotoExhibitionId: String? = nil
  var deletePhotoId: String? = nil

  // 成功/失敗のシミュレーション
  var shouldSucceed: Bool = true
  var errorToThrow: Error? = nil

  // MARK: - PhotoClientプロトコルの実装

  func fetchPhotos(exhibitionId: String) async throws -> [Photo] {
    fetchPhotosWasCalled = true
    fetchPhotosExhibitionId = exhibitionId

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    return mockPhotos
  }

  func addPhoto(exhibitionId: String, path: String) async throws -> Photo {
    addPhotoWasCalled = true
    addPhotoExhibitionId = exhibitionId
    addPhotoPath = path

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    if let mockPhoto = mockAddedPhoto {
      return mockPhoto
    }

    // デフォルトのモック写真を返す
    return Photo(
      id: "mock-photo-id",
      path: path,
      createdAt: Date(),
      updatedAt: Date()
    )
  }

  func deletePhoto(exhibitionId: String, photoId: String) async throws {
    deletePhotoWasCalled = true
    deletePhotoExhibitionId = exhibitionId
    deletePhotoId = photoId

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    fetchPhotosWasCalled = false
    fetchPhotosExhibitionId = nil

    addPhotoWasCalled = false
    addPhotoExhibitionId = nil
    addPhotoPath = nil

    deletePhotoWasCalled = false
    deletePhotoExhibitionId = nil
    deletePhotoId = nil

    shouldSucceed = true
    errorToThrow = nil
  }
}
