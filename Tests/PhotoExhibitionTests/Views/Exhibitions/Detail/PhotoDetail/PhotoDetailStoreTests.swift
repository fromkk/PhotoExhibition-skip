import XCTest

@testable import PhotoExhibition

@MainActor
final class PhotoDetailStoreTests: XCTestCase {
  private var mockPhotoClient: MockPhotoClient!
  private var mockImageCache: MockStorageImageCache!
  private var store: PhotoDetailStore!
  private let exhibitionId = "test-exhibition-id"
  private let photo = Photo(
    id: "test-photo-id",
    path: "test-path",
    title: "Test Photo",
    description: "Test Description",
    takenDate: Date(),
    photographer: "Test Photographer",
    createdAt: Date(),
    updatedAt: Date()
  )

  override func setUp() async throws {
    mockPhotoClient = MockPhotoClient()
    mockImageCache = MockStorageImageCache()
    store = PhotoDetailStore(
      exhibitionId: exhibitionId,
      photo: photo,
      isOrganizer: true,
      imageCache: mockImageCache,
      photoClient: mockPhotoClient
    )
  }

  func testLoadImage() async throws {
    // 準備
    let expectedURL = URL(string: "https://example.com/test-image.jpg")!
    mockImageCache.mockImageURL = expectedURL

    // 実行
    store.send(PhotoDetailStore.Action.loadImage)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockImageCache.getImageURLWasCalled)
    XCTAssertEqual(mockImageCache.getImageURLPath, "test-path")
    XCTAssertEqual(store.imageURL, expectedURL)
    XCTAssertFalse(store.isLoading)
  }

  func testUpdatePhoto() async throws {
    // 準備
    let title = "Updated Title"
    let description = "Updated Description"

    // 実行
    store.send(PhotoDetailStore.Action.updatePhoto(title: title, description: description))

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockPhotoClient.updatePhotoWasCalled)
    XCTAssertEqual(mockPhotoClient.updatePhotoExhibitionId, exhibitionId)
    XCTAssertEqual(mockPhotoClient.updatePhotoId, photo.id)
    XCTAssertEqual(mockPhotoClient.updatePhotoTitle, title)
    XCTAssertEqual(mockPhotoClient.updatePhotoDescription, description)
    XCTAssertFalse(store.showEditSheet)
  }

  func testDeletePhoto() async throws {
    // 実行
    store.send(PhotoDetailStore.Action.deleteButtonTapped)

    // 検証
    XCTAssertTrue(store.showDeleteConfirmation)

    // 削除を確認
    store.send(PhotoDetailStore.Action.confirmDeletePhoto)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockPhotoClient.deletePhotoWasCalled)
    XCTAssertEqual(mockPhotoClient.deletePhotoExhibitionId, exhibitionId)
    XCTAssertEqual(mockPhotoClient.deletePhotoId, photo.id)
    XCTAssertFalse(store.showDeleteConfirmation)
    XCTAssertTrue(store.isDeleted)
  }

  func testDeletePhotoFailure() async throws {
    // 準備
    mockPhotoClient.shouldSucceed = false
    mockPhotoClient.errorToThrow = NSError(domain: "test", code: 1, userInfo: nil)

    // 実行
    store.send(PhotoDetailStore.Action.deleteButtonTapped)
    store.send(PhotoDetailStore.Action.confirmDeletePhoto)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockPhotoClient.deletePhotoWasCalled)
    XCTAssertNotNil(store.error)
    XCTAssertFalse(store.isDeleted)
  }
}
