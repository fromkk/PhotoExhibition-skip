import XCTest

@testable import PhotoExhibition

#if SKIP
  import SkipFirebaseCore
#else
  import FirebaseCore
#endif

@MainActor
final class MockExhibitionEditStoreDelegate: ExhibitionEditStoreDelegate {
  var didSaveExhibitionCalled = false
  var didCancelExhibitionCalled = false

  func didSaveExhibition() {
    didSaveExhibitionCalled = true
  }

  func didCancelExhibition() {
    didCancelExhibitionCalled = true
  }

  func reset() {
    didSaveExhibitionCalled = false
    didCancelExhibitionCalled = false
  }
}

@MainActor
final class ExhibitionEditStoreTests: XCTestCase {
  // テスト用のモックデータ
  private var testExhibition: Exhibition!
  private var mockExhibitionsClient: MockExhibitionsClient!
  private var mockCurrentUserClient: MockCurrentUserClient!
  private var mockStorageClient: MockStorageClient!
  private var mockStorageImageCache: MockStorageImageCache!
  private var mockAnalyticsClient: MockAnalyticsClient!
  private var mockPhotoClient: MockPhotoClient!
  private var mockMember: Member!

  override func setUp() async throws {
    // モックメンバーを作成
    mockMember = Member(
      id: "test-user-id",
      name: "Test User",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    // テスト用の展示会データを作成
    testExhibition = Exhibition(
      id: "test-exhibition-id",
      name: "Test Exhibition",
      description: "Test Description",
      from: Date(),
      to: Date().addingTimeInterval(60 * 60 * 24 * 7),  // 1週間後
      organizer: mockMember,
      coverImagePath: "test/cover-image.jpg",
      createdAt: Date(),
      updatedAt: Date()
    )

    // モックの作成
    mockExhibitionsClient = MockExhibitionsClient()
    mockCurrentUserClient = MockCurrentUserClient()
    mockStorageClient = MockStorageClient()
    mockStorageImageCache = MockStorageImageCache()
    mockAnalyticsClient = MockAnalyticsClient()
    mockPhotoClient = MockPhotoClient()

    // CurrentUserClientのモック設定
    mockCurrentUserClient.mockUser = User(uid: mockMember.id)
  }

  override func tearDown() async throws {
    testExhibition = nil
    mockExhibitionsClient = nil
    mockCurrentUserClient = nil
    mockStorageClient = nil
    mockStorageImageCache = nil
    mockAnalyticsClient = nil
    mockPhotoClient = nil
  }

  // MARK: - 初期化のテスト

  func testInitWithCreateMode() {
    // 作成モードでストアを初期化
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 初期値を確認
    XCTAssertEqual(store.name, "")
    XCTAssertEqual(store.description, "")
    XCTAssertFalse(store.isLoading)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.showError)
    XCTAssertFalse(store.shouldDismiss)
    XCTAssertFalse(store.imagePickerPresented)
    XCTAssertNil(store.pickedImageURL)
    XCTAssertNil(store.coverImageURL)
  }

  func testInitWithEditMode() {
    // 編集モードでストアを初期化
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.edit(testExhibition),
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 初期値を確認
    XCTAssertEqual(store.name, "Test Exhibition")
    XCTAssertEqual(store.description, "Test Description")
    XCTAssertFalse(store.isLoading)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.showError)
    XCTAssertFalse(store.shouldDismiss)
    XCTAssertFalse(store.imagePickerPresented)
    XCTAssertNil(store.pickedImageURL)
  }

  func testInitWithEditModeLoadsExistingCoverImage() async {
    // モックの画像URLを設定
    mockStorageImageCache.mockImageURL = URL(
      string: "file:///mock/image/path/test_cover-image.jpg")!

    // 編集モードでストアを初期化
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.edit(testExhibition),
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 非同期処理の完了を待つ
    try? await Task.sleep(nanoseconds: 100_000_000)

    // StorageImageCacheのgetImageURLメソッドが呼ばれたことを確認
    XCTAssertTrue(mockStorageImageCache.getImageURLWasCalled, "getImageURL method should be called")
    XCTAssertEqual(
      mockStorageImageCache.getImageURLPath, "test/cover-image.jpg",
      "Correct path should be passed to getImageURL method")

    // coverImageURLが設定されることを確認
    XCTAssertEqual(store.coverImageURL, mockStorageImageCache.mockImageURL)
  }

  // MARK: - アクションのテスト

  func testUpdateNameAction() {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 名前を更新
    store.name = "New Exhibition Name"

    // 名前が更新されることを確認
    XCTAssertEqual(store.name, "New Exhibition Name")
  }

  func testUpdateDescriptionAction() {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 説明を更新
    store.description = "New Description"

    // 説明が更新されることを確認
    XCTAssertEqual(store.description, "New Description")
  }

  func testUpdateFromAction() {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 開始日を設定
    let newFrom = Date().addingTimeInterval(60 * 60 * 24 * 2)  // 2日後
    store.send(ExhibitionEditStore.Action.updateFrom(newFrom))

    // 開始日が更新されることを確認
    XCTAssertEqual(store.from, newFrom)
  }

  func testUpdateFromActionAdjustsToDateIfNeeded() {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 初期の終了日を設定
    let initialTo = Date().addingTimeInterval(60 * 60 * 24)  // 1日後
    store.send(ExhibitionEditStore.Action.updateTo(initialTo))

    // 開始日を終了日より後に設定
    let newFrom = Date().addingTimeInterval(60 * 60 * 24 * 2)  // 2日後
    store.send(ExhibitionEditStore.Action.updateFrom(newFrom))

    // 開始日が更新されることを確認
    XCTAssertEqual(store.from, newFrom)

    // 終了日が自動的に調整されることを確認
    XCTAssertGreaterThan(store.to, store.from)
  }

  func testUpdateToAction() {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 終了日を設定
    let newTo = Date().addingTimeInterval(60 * 60 * 24 * 14)  // 14日後
    store.send(ExhibitionEditStore.Action.updateTo(newTo))

    // 終了日が更新されることを確認
    XCTAssertEqual(store.to, newTo)
  }

  func testChangeCoverImageButtonTappedAction() {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 画像選択アクションを送信
    store.send(ExhibitionEditStore.Action.changeCoverImageButtonTapped)

    // 画像選択が表示されることを確認
    XCTAssertTrue(store.imagePickerPresented)
  }

  func testUpdateCoverImageAction() {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // カバー画像更新アクションを送信
    let imageURL = URL(string: "https://example.com/test-image.jpg")!
    store.send(ExhibitionEditStore.Action.updateCoverImage(imageURL))

    // カバー画像URLが更新されることを確認
    XCTAssertEqual(store.coverImageURL, imageURL)
  }

  func testCancelAction() {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // キャンセルアクションを送信
    store.send(ExhibitionEditStore.Action.cancelButtonTapped)

    // shouldDismissがtrueになることを確認
    XCTAssertTrue(store.shouldDismiss)
  }

  // MARK: - 保存機能のテスト

  func testSaveActionWithEmptyNameShowsError() async throws {
    // Arrange
    let mockUser = User(uid: "test-user-id")
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )
    mockCurrentUserClient.mockUser = mockUser
    store.name = ""

    // Act
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertNotNil(store.error, "エラーが設定されるべきです")
    if let error = store.error {
      XCTAssertTrue(
        error.localizedDescription.contains("Please enter exhibition name"), "エラーメッセージが正しくありません")
    }
    XCTAssertTrue(store.showError, "エラーが表示されるべきです")
    XCTAssertFalse(store.shouldDismiss, "エラー時に画面が閉じられるべきではありません")
  }

  func testSaveActionWithNoUserShowsError() async throws {
    // Arrange
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )
    mockCurrentUserClient.mockUser = nil
    store.name = "Exhibition"

    // Act
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertNotNil(store.error, "エラーが設定されるべきです")
    if let error = store.error {
      XCTAssertTrue(error.localizedDescription.contains("Please login"), "エラーメッセージが正しくありません")
    }
    XCTAssertTrue(store.showError, "エラーが表示されるべきです")
    XCTAssertFalse(store.shouldDismiss, "エラー時に画面が閉じられるべきではありません")
  }

  func testSaveActionInCreateModeCallsCreateOnExhibitionsClient() async {
    // 現在のユーザーを設定
    mockCurrentUserClient.mockUser = User(uid: "test-user-id")

    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 展示会情報を設定
    store.name = "Test Exhibition"
    store.description = "Test Description"

    // 画像を選択
    let pickedImageURL = URL(string: "file:///tmp/test-image.jpg")!
    store.pickedImageURL = pickedImageURL

    // 保存アクションを送信
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    try? await Task.sleep(nanoseconds: 100_000_000)

    // createWithIdメソッドが呼ばれたことを確認（基本情報の作成）
    XCTAssertTrue(mockExhibitionsClient.createWithIdWasCalled)

    // 基本情報が正しく作成されていることを確認
    XCTAssertEqual(mockExhibitionsClient.createdWithIdData?["name"] as? String, "Test Exhibition")
    XCTAssertEqual(
      mockExhibitionsClient.createdWithIdData?["description"] as? String, "Test Description")
    XCTAssertEqual(mockExhibitionsClient.createdWithIdData?["organizer"] as? String, "test-user-id")

    // 画像アップロードが呼ばれたことを確認
    XCTAssertTrue(mockStorageClient.uploadWasCalled)
    XCTAssertEqual(mockStorageClient.uploadFromURL, pickedImageURL)

    // 正しいパスにアップロードされていることを確認
    XCTAssertNotNil(mockStorageClient.uploadToPath)
    if let path = mockStorageClient.uploadToPath {
      XCTAssertTrue(path.starts(with: "exhibitions/"), "Path should start with 'exhibitions/'")
      XCTAssertTrue(path.contains("/cover."), "Path should contain '/cover.'")
    }

    // 成功したらshouldDismissがtrueになることを確認
    XCTAssertTrue(store.shouldDismiss)
  }

  func testSaveActionInEditModeCallsUpdateOnExhibitionsClient() async {
    // 現在のユーザーを設定
    mockCurrentUserClient.mockUser = User(uid: "test-user-id")

    // モックの動作を設定
    mockExhibitionsClient.shouldSucceed = true

    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.edit(testExhibition),
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 展示会情報を設定
    store.name = "Updated Exhibition"
    store.description = "Updated Description"

    // 画像を選択
    let pickedImageURL = URL(string: "file:///tmp/test-image.jpg")!
    store.pickedImageURL = pickedImageURL

    // 保存アクションを送信前にモックの状態をキャプチャするための変数を準備
    var capturedData: [String: Any]? = nil

    // モックの動作をカスタマイズ - updateが呼ばれたときにデータをキャプチャ
    mockExhibitionsClient.updateCallback = { id, data in
      if capturedData == nil {
        capturedData = data
      }
    }

    // 保存アクションを送信
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    try? await Task.sleep(nanoseconds: 100_000_000)

    // updateメソッドが呼ばれたことを確認
    XCTAssertTrue(mockExhibitionsClient.updateWasCalled)
    XCTAssertEqual(mockExhibitionsClient.updatedId, "test-exhibition-id")

    // キャプチャしたデータを検証
    XCTAssertNotNil(capturedData, "updateに渡されたデータがキャプチャされていません")

    if let data = capturedData {
      XCTAssertEqual(data["name"] as? String, "Updated Exhibition")
      XCTAssertEqual(data["description"] as? String, "Updated Description")
      XCTAssertEqual(data["organizer"] as? String, "test-user-id")

      // Timestampが含まれていることを確認
      XCTAssertNotNil(data["from"])
      XCTAssertNotNil(data["to"])
      XCTAssertNotNil(data["updatedAt"])
    }

    // 画像アップロードが呼ばれたことを確認
    XCTAssertTrue(mockStorageClient.uploadWasCalled)
    XCTAssertEqual(mockStorageClient.uploadFromURL, pickedImageURL)

    // 正しいパスにアップロードされていることを確認
    XCTAssertNotNil(mockStorageClient.uploadToPath)
    if let path = mockStorageClient.uploadToPath {
      XCTAssertTrue(
        path.starts(with: "exhibitions/\(testExhibition.id)/"),
        "Path should start with 'exhibitions/{id}/'")
      XCTAssertTrue(path.contains("/cover."), "Path should contain '/cover.'")
    }

    // 成功したらshouldDismissがtrueになることを確認
    XCTAssertTrue(store.shouldDismiss)
  }

  func testSaveActionWithPickedImageUploadsImage() async {
    // 現在のユーザーを設定
    mockCurrentUserClient.mockUser = User(uid: "test-user-id")

    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 展示会情報を設定
    store.name = "New Exhibition"

    // 画像を選択
    let pickedImageURL = URL(string: "file:///tmp/test-image.jpg")!
    store.pickedImageURL = pickedImageURL

    // 保存アクションを送信
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    try? await Task.sleep(nanoseconds: 100_000_000)

    // createWithIdメソッドが呼ばれたことを確認（基本情報の作成）
    XCTAssertTrue(mockExhibitionsClient.createWithIdWasCalled)

    // 画像アップロードが呼ばれたことを確認
    XCTAssertTrue(mockStorageClient.uploadWasCalled)
    XCTAssertEqual(mockStorageClient.uploadFromURL, pickedImageURL)

    // 正しいパスにアップロードされていることを確認
    XCTAssertNotNil(mockStorageClient.uploadToPath)
    if let path = mockStorageClient.uploadToPath {
      XCTAssertTrue(path.starts(with: "exhibitions/"), "Path should start with 'exhibitions/'")
      XCTAssertTrue(path.contains("/cover."), "Path should contain '/cover.'")
    }

    // 成功したらshouldDismissがtrueになることを確認
    XCTAssertTrue(store.shouldDismiss)
  }

  func testSaveActionHandlesError() async throws {
    // Arrange
    let mockUser = User(uid: "test-user-id")
    mockCurrentUserClient.mockUser = mockUser
    mockExhibitionsClient.shouldSucceed = false
    mockExhibitionsClient.errorToThrow = NSError(
      domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Save error"])

    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )
    store.name = "Test Exhibition"

    // Act
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertNotNil(store.error, "エラーが設定されるべきです")
    if let error = store.error {
      XCTAssertTrue(error.localizedDescription.contains("Save error"), "エラーメッセージが正しくありません")
    }
    XCTAssertTrue(store.showError, "エラーが表示されるべきです")
    XCTAssertFalse(store.shouldDismiss, "エラー時に画面が閉じられるべきではありません")
  }

  func testSaveButtonTappedCallsDelegate() async throws {
    // 準備
    let mockDelegate = MockExhibitionEditStoreDelegate()
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      delegate: mockDelegate,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 必要な情報を設定
    store.name = "Test Exhibition"
    mockCurrentUserClient.mockUser = User(uid: "test-user-id")

    // 実行
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockDelegate.didSaveExhibitionCalled, "Delegate method should be called")
  }

  func testCancelButtonTappedCallsDelegate() async throws {
    // 準備
    let mockDelegate = MockExhibitionEditStoreDelegate()
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      delegate: mockDelegate,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      analyticsClient: mockAnalyticsClient
    )

    // 実行
    store.send(ExhibitionEditStore.Action.cancelButtonTapped)

    // 検証
    XCTAssertTrue(mockDelegate.didCancelExhibitionCalled, "Delegate method should be called")
  }

  // MARK: - ステータス変更のテスト

  func testStatusChangedActionToPublishedWithNoPhotosShowsError() async throws {
    // Setup
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.edit(testExhibition),
      delegate: nil,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      analyticsClient: mockAnalyticsClient,
      photoClient: mockPhotoClient
    )

    // 写真がない状態を設定
    mockPhotoClient.fetchPhotosResult = []

    // Act
    store.send(ExhibitionEditStore.Action.statusChanged(ExhibitionStatus.published))
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒待機

    // Assert
    XCTAssertNotNil(store.error)
    XCTAssertTrue(store.showError)
    XCTAssertTrue(mockPhotoClient.fetchPhotosWasCalled)
    XCTAssertEqual(mockPhotoClient.fetchPhotosExhibitionId, testExhibition.id)
    XCTAssertEqual(store.status, ExhibitionStatus.draft)
  }

  func testStatusChangedActionToPublishedWithPhotosSucceeds() async throws {
    // Setup
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.edit(testExhibition),
      delegate: nil,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      analyticsClient: mockAnalyticsClient,
      photoClient: mockPhotoClient
    )

    // テスト用の写真を作成
    let testPhoto = Photo(
      id: "id",
      path: "path",
      path_256x256: nil,
      path_512x512: nil,
      path_1024x1024: nil,
      title: "title",
      description: "description",
      metadata: nil,
      sort: 0,
      createdAt: Date(),
      updatedAt: Date()
    )
    mockPhotoClient.fetchPhotosResult = [testPhoto]

    // Act
    store.send(ExhibitionEditStore.Action.statusChanged(ExhibitionStatus.published))
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒待機

    // Assert
    XCTAssertNil(store.error)
    XCTAssertFalse(store.showError)
    XCTAssertTrue(mockPhotoClient.fetchPhotosWasCalled)
    XCTAssertEqual(mockPhotoClient.fetchPhotosExhibitionId, testExhibition.id)
    XCTAssertEqual(store.status, ExhibitionStatus.published)
  }

  func testSaveExhibitionWithPublishedStatusAndNoPhotosShowsError() async throws {
    // Setup
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.edit(testExhibition),
      delegate: nil,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      analyticsClient: mockAnalyticsClient,
      photoClient: mockPhotoClient
    )

    // 写真がない状態を設定
    mockPhotoClient.fetchPhotosResult = []

    // 公開ステータスに設定
    store.status = ExhibitionStatus.published

    // Act
    store.send(ExhibitionEditStore.Action.saveButtonTapped)
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒待機

    // Assert
    XCTAssertNotNil(store.error)
    XCTAssertTrue(store.showError)
    XCTAssertTrue(mockPhotoClient.fetchPhotosWasCalled)
    XCTAssertEqual(mockPhotoClient.fetchPhotosExhibitionId, testExhibition.id)
    XCTAssertFalse(mockExhibitionsClient.updateWasCalled)
  }

  func testSaveExhibitionInCreateModeWithPublishedStatusAutomaticallySetsToDraft() async throws {
    // Setup
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      delegate: nil,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      analyticsClient: mockAnalyticsClient,
      photoClient: mockPhotoClient
    )

    store.name = "Test Exhibition"
    store.status = ExhibitionStatus.published

    // Act
    store.send(ExhibitionEditStore.Action.saveButtonTapped)
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒待機

    // Assert
    XCTAssertNil(store.error)
    XCTAssertTrue(mockExhibitionsClient.createWithIdWasCalled)
    // 新規作成時は常にdraftになることを確認
    if let data = mockExhibitionsClient.createdWithIdData {
      XCTAssertEqual(data["status"] as? String, ExhibitionStatus.draft.rawValue)
    }
  }
}
