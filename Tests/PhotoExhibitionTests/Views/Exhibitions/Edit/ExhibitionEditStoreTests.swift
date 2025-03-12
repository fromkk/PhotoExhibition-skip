import XCTest

@testable import PhotoExhibition

@MainActor
final class ExhibitionEditStoreTests: XCTestCase {
  // テスト用のモックデータ
  private var testExhibition: Exhibition!
  private var mockExhibitionsClient: MockExhibitionsClient!
  private var mockCurrentUserClient: MockCurrentUserClient!
  private var mockStorageClient: MockStorageClient!

  override func setUp() async throws {
    // テスト用の展示会データを作成
    testExhibition = Exhibition(
      id: "test-exhibition-id",
      name: "Test Exhibition",
      description: "Test Description",
      from: Date(),
      to: Date().addingTimeInterval(60 * 60 * 24 * 7),  // 1週間後
      organizer: Member(
        id: "organizer-id",
        name: "Organizer Name",
        icon: nil,
        createdAt: Date(),
        updatedAt: Date()
      ),
      coverImagePath: "test/cover-image.jpg",
      createdAt: Date(),
      updatedAt: Date()
    )

    // モックの作成
    mockExhibitionsClient = MockExhibitionsClient()
    mockCurrentUserClient = MockCurrentUserClient()
    mockStorageClient = MockStorageClient()
  }

  override func tearDown() async throws {
    testExhibition = nil
    mockExhibitionsClient = nil
    mockCurrentUserClient = nil
    mockStorageClient = nil
  }

  // MARK: - 初期化のテスト

  func testInitWithCreateMode() {
    // 作成モードでストアを初期化
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient
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
      storageClient: mockStorageClient
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
    // 編集モードでストアを初期化
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.edit(testExhibition),
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient
    )

    // 非同期処理の完了を待つ
    await fulfillment(of: [mockStorageClient.urlExpectation], timeout: 1.0)

    // StorageClientのurlメソッドが呼ばれたことを確認
    XCTAssertTrue(mockStorageClient.urlWasCalled, "URL method should be called")
    XCTAssertEqual(
      mockStorageClient.urlPath, "test/cover-image.jpg",
      "Correct path should be passed to URL method")

    // coverImageURLが設定されることを確認
    XCTAssertEqual(store.coverImageURL, mockStorageClient.mockURL)
  }

  // MARK: - アクションのテスト

  func testUpdateNameAction() {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient
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
      storageClient: mockStorageClient
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
      storageClient: mockStorageClient
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
      storageClient: mockStorageClient
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
      storageClient: mockStorageClient
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
      storageClient: mockStorageClient
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
      storageClient: mockStorageClient
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
      storageClient: mockStorageClient
    )

    // キャンセルアクションを送信
    store.send(ExhibitionEditStore.Action.cancelButtonTapped)

    // shouldDismissがtrueになることを確認
    XCTAssertTrue(store.shouldDismiss)
  }

  // MARK: - 保存機能のテスト

  func testSaveActionWithEmptyNameShowsError() async {
    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient
    )

    // 名前を空に設定
    store.name = ""

    // 保存アクションを送信
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // エラーが表示されることを確認
    XCTAssertEqual(store.error, ExhibitionEditError.emptyName)
    XCTAssertTrue(store.showError)
    XCTAssertFalse(store.shouldDismiss)
  }

  func testSaveActionWithNoUserShowsError() async {
    // 現在のユーザーをnilに設定
    mockCurrentUserClient.mockUser = nil

    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient
    )

    // 名前を設定
    store.name = "Test Exhibition"

    // 保存アクションを送信
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // エラーが表示されることを確認
    XCTAssertEqual(store.error, ExhibitionEditError.userNotLoggedIn)
    XCTAssertTrue(store.showError)
    XCTAssertFalse(store.shouldDismiss)
  }

  func testSaveActionInCreateModeCallsCreateOnExhibitionsClient() async {
    // 現在のユーザーを設定
    mockCurrentUserClient.mockUser = User(uid: "test-user-id")

    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient
    )

    // 展示会情報を設定
    store.name = "New Exhibition"
    store.description = "New Description"

    // 保存アクションを送信
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    await fulfillment(of: [mockExhibitionsClient.createExpectation], timeout: 1.0)

    // createメソッドが呼ばれたことを確認
    XCTAssertTrue(mockExhibitionsClient.createWasCalled)

    // 正しいデータが渡されたことを確認
    XCTAssertEqual(mockExhibitionsClient.createdData?["name"] as? String, "New Exhibition")
    XCTAssertEqual(mockExhibitionsClient.createdData?["description"] as? String, "New Description")
    XCTAssertEqual(mockExhibitionsClient.createdData?["organizer"] as? String, "test-user-id")

    // 成功したらshouldDismissがtrueになることを確認
    XCTAssertTrue(store.shouldDismiss)
  }

  func testSaveActionInEditModeCallsUpdateOnExhibitionsClient() async {
    // 現在のユーザーを設定
    mockCurrentUserClient.mockUser = User(uid: "test-user-id")

    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.edit(testExhibition),
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient
    )

    // 展示会情報を設定
    store.name = "Updated Exhibition"
    store.description = "Updated Description"

    // 保存アクションを送信
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    await fulfillment(of: [mockExhibitionsClient.updateExpectation], timeout: 1.0)

    // updateメソッドが呼ばれたことを確認
    XCTAssertTrue(mockExhibitionsClient.updateWasCalled)
    XCTAssertEqual(mockExhibitionsClient.updatedId, "test-exhibition-id")

    // 正しいデータが渡されたことを確認
    XCTAssertEqual(mockExhibitionsClient.updatedData?["name"] as? String, "Updated Exhibition")
    XCTAssertEqual(
      mockExhibitionsClient.updatedData?["description"] as? String, "Updated Description")
    XCTAssertEqual(mockExhibitionsClient.updatedData?["organizer"] as? String, "test-user-id")

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
      storageClient: mockStorageClient
    )

    // 展示会情報を設定
    store.name = "New Exhibition"

    // 画像を選択
    let pickedImageURL = URL(string: "file:///tmp/test-image.jpg")!
    store.pickedImageURL = pickedImageURL

    // 保存アクションを送信
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    await fulfillment(
      of: [mockStorageClient.uploadExpectation, mockExhibitionsClient.createExpectation],
      timeout: 1.0
    )

    // 画像アップロードが呼ばれたことを確認
    XCTAssertTrue(mockStorageClient.uploadWasCalled)
    XCTAssertEqual(mockStorageClient.uploadFromURL, pickedImageURL)
    XCTAssertTrue(mockStorageClient.uploadToPath?.starts(with: "members/test-user-id/") ?? false)

    // createメソッドが呼ばれたことを確認
    XCTAssertTrue(mockExhibitionsClient.createWasCalled)

    // coverImagePathが設定されていることを確認
    XCTAssertNotNil(mockExhibitionsClient.createdData?["coverImagePath"])

    // 成功したらshouldDismissがtrueになることを確認
    XCTAssertTrue(store.shouldDismiss)
  }

  func testSaveActionHandlesError() async {
    // 現在のユーザーを設定
    mockCurrentUserClient.mockUser = User(uid: "test-user-id")

    // 保存失敗を設定
    mockExhibitionsClient.shouldSucceed = false
    mockExhibitionsClient.errorToThrow = NSError(
      domain: "test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Save error"])

    // ストアの作成
    let store = ExhibitionEditStore(
      mode: ExhibitionEditStore.Mode.create,
      currentUserClient: mockCurrentUserClient,
      exhibitionsClient: mockExhibitionsClient,
      storageClient: mockStorageClient
    )

    // 展示会情報を設定
    store.name = "New Exhibition"

    // 保存アクションを送信
    store.send(ExhibitionEditStore.Action.saveButtonTapped)

    // 非同期処理の完了を待つ
    await fulfillment(of: [mockExhibitionsClient.createExpectation], timeout: 1.0)

    // エラーが設定されることを確認
    XCTAssertNotNil(store.error)
    if let error = store.error, case ExhibitionEditError.saveFailed(let message) = error {
      XCTAssertEqual(message, "Save error")
    } else {
      XCTFail("Expected saveFailed error")
    }

    XCTAssertTrue(store.showError)

    // エラー時はshouldDismissがfalseのままであることを確認
    XCTAssertFalse(store.shouldDismiss)
  }
}
