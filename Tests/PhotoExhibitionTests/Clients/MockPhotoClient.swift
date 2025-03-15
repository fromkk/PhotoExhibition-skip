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

  // updatePhoto()の呼び出し追跡
  var updatePhotoWasCalled: Bool = false
  var updatePhotoExhibitionId: String? = nil
  var updatePhotoId: String? = nil
  var updatePhotoTitle: String? = nil
  var updatePhotoDescription: String? = nil

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

  func updatePhoto(exhibitionId: String, photoId: String, title: String?, description: String?)
    async throws
  {
    updatePhotoWasCalled = true
    updatePhotoExhibitionId = exhibitionId
    updatePhotoId = photoId
    updatePhotoTitle = title
    updatePhotoDescription = description

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
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

    updatePhotoWasCalled = false
    updatePhotoExhibitionId = nil
    updatePhotoId = nil
    updatePhotoTitle = nil
    updatePhotoDescription = nil

    deletePhotoWasCalled = false
    deletePhotoExhibitionId = nil
    deletePhotoId = nil

    shouldSucceed = true
    errorToThrow = nil
  }
}
