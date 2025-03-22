import XCTest

@testable import PhotoExhibition

@MainActor
final class ProfileSetupStoreTests: XCTestCase {
  var mockMemberUpdateClient: MockMemberUpdateClient!
  var mockStorageClient: MockStorageClient!
  var mockDelegate: MockProfileSetupStoreDelegate!
  var mockImageCache: MockStorageImageCache!

  override func setUp() async throws {
    mockMemberUpdateClient = MockMemberUpdateClient()
    mockStorageClient = MockStorageClient()
    mockDelegate = MockProfileSetupStoreDelegate()
    mockImageCache = MockStorageImageCache()
  }

  override func tearDown() async throws {
    mockMemberUpdateClient = nil
    mockStorageClient = nil
    mockDelegate = nil
    mockImageCache = nil
  }

  func testInit() {
    // Arrange
    let testMember = Member(
      id: "test-id",
      name: "Test User",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    // Act
    let store = ProfileSetupStore(
      member: testMember,
      memberUpdateClient: mockMemberUpdateClient,
      storageClient: mockStorageClient,
      imageCache: mockImageCache
    )

    // Assert
    XCTAssertEqual(store.name, "Test User")
    XCTAssertNil(store.iconPath)
    XCTAssertNil(store.iconImageURL)
    XCTAssertNil(store.selectedIconURL)
    XCTAssertFalse(store.iconPickerPresented)
    XCTAssertFalse(store.isLoading)
  }

  func testInitWithIcon() async {
    // Arrange
    let iconPath = "members/test-id/icons/test-icon.jpg"
    let testMember = Member(
      id: "test-id",
      name: "Test User",
      icon: iconPath,
      createdAt: Date(),
      updatedAt: Date()
    )
    let mockURL = URL(string: "https://example.com/test-icon.jpg")!
    mockImageCache.mockImageURL = mockURL

    // Act
    let store = ProfileSetupStore(
      member: testMember,
      memberUpdateClient: mockMemberUpdateClient,
      storageClient: mockStorageClient,
      imageCache: mockImageCache
    )

    // イメージURLが非同期で取得されるため、少し待機
    try? await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertEqual(store.name, "Test User")
    XCTAssertEqual(store.iconPath, iconPath)
    XCTAssertTrue(mockImageCache.getImageURLWasCalled)
    XCTAssertEqual(mockImageCache.getImageURLPath, iconPath)
    XCTAssertEqual(store.iconImageURL, mockURL)
  }

  func testSelectIconButtonTapped() {
    // Arrange
    let testMember = Member(
      id: "test-id",
      name: "Test User",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )
    let store = ProfileSetupStore(
      member: testMember,
      memberUpdateClient: mockMemberUpdateClient,
      storageClient: mockStorageClient,
      imageCache: mockImageCache
    )

    // Act
    store.send(ProfileSetupStore.Action.selectIconButtonTapped)

    // Assert
    XCTAssertTrue(store.iconPickerPresented)
  }

  func testIconSelected() {
    // Arrange
    let testMember = Member(
      id: "test-id",
      name: "Test User",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )
    let store = ProfileSetupStore(
      member: testMember,
      memberUpdateClient: mockMemberUpdateClient,
      storageClient: mockStorageClient,
      imageCache: mockImageCache
    )
    let iconURL = URL(string: "file:///test/path/icon.jpg")!

    // Act
    store.send(ProfileSetupStore.Action.iconSelected(iconURL))

    // Assert
    XCTAssertEqual(store.selectedIconURL, iconURL)
  }

  func testSaveButtonTappedWithNameOnly() async {
    // Arrange
    let testMember = Member(
      id: "test-id",
      name: nil,
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )
    let newName = "New Name"

    let store = ProfileSetupStore(
      member: testMember,
      memberUpdateClient: mockMemberUpdateClient,
      storageClient: mockStorageClient,
      imageCache: mockImageCache
    )
    store.delegate = mockDelegate
    store.name = newName

    // Act
    store.send(ProfileSetupStore.Action.saveButtonTapped)

    // 非同期処理が完了するのを待つ
    try? await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertTrue(mockMemberUpdateClient.updateProfileWasCalled)
    XCTAssertEqual(mockMemberUpdateClient.updatedProfileMemberID, testMember.id)
    XCTAssertEqual(mockMemberUpdateClient.updatedProfileName, newName)
    XCTAssertNil(mockMemberUpdateClient.updatedProfileIconPath)
    XCTAssertFalse(store.isLoading)
    XCTAssertTrue(mockDelegate.didCompleteProfileSetupCalled)
  }

  func testSaveButtonTappedWithNameAndIcon() async {
    // Arrange
    let testMember = Member(
      id: "test-id",
      name: nil,
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )
    let newName = "New Name"
    let iconURL = URL(string: "file:///test/path/icon.jpg")!
    mockStorageClient.mockUploadURL = URL(string: "https://example.com/uploaded-icon.jpg")!

    let store = ProfileSetupStore(
      member: testMember,
      memberUpdateClient: mockMemberUpdateClient,
      storageClient: mockStorageClient,
      imageCache: mockImageCache
    )
    store.delegate = mockDelegate
    store.name = newName
    store.selectedIconURL = iconURL

    // Act
    store.send(ProfileSetupStore.Action.saveButtonTapped)

    // 非同期処理が完了するのを待つ
    try? await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertTrue(mockStorageClient.uploadWasCalled)
    XCTAssertEqual(mockStorageClient.uploadFromURL, iconURL)
    XCTAssertTrue(
      mockStorageClient.uploadToPath?.starts(with: "members/\(testMember.id)/icon_") ?? false,
      "Path should start with members/{member.id}/icon_ but was \(mockStorageClient.uploadToPath ?? "nil")"
    )

    XCTAssertTrue(mockMemberUpdateClient.updateProfileWasCalled)
    XCTAssertEqual(mockMemberUpdateClient.updatedProfileMemberID, testMember.id)
    XCTAssertEqual(mockMemberUpdateClient.updatedProfileName, newName)
    XCTAssertNotNil(mockMemberUpdateClient.updatedProfileIconPath)
    XCTAssertFalse(store.isLoading)
    XCTAssertTrue(mockDelegate.didCompleteProfileSetupCalled)
  }

  func testSaveButtonTappedWithError() async {
    // Arrange
    let testMember = Member(
      id: "test-id",
      name: nil,
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )
    mockMemberUpdateClient.shouldSucceed = false
    mockMemberUpdateClient.errorToThrow = MemberUpdateClientError.updateFailed

    let store = ProfileSetupStore(
      member: testMember,
      memberUpdateClient: mockMemberUpdateClient,
      storageClient: mockStorageClient,
      imageCache: mockImageCache
    )
    store.delegate = mockDelegate
    store.name = "New Name"

    // Act
    store.send(ProfileSetupStore.Action.saveButtonTapped)

    // 非同期処理が完了するのを待つ
    try? await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertTrue(mockMemberUpdateClient.updateProfileWasCalled)
    XCTAssertFalse(store.isLoading)
    XCTAssertTrue(store.isErrorAlertPresented)
    XCTAssertNotNil(store.error)
    XCTAssertFalse(mockDelegate.didCompleteProfileSetupCalled)
  }

  func testRemoveIcon() async {
    // Arrange
    let iconPath = "members/test-id/icons/test-icon.jpg"
    let testMember = Member(
      id: "test-id",
      name: "Test User",
      icon: iconPath,
      createdAt: Date(),
      updatedAt: Date()
    )
    let mockURL = URL(string: "https://example.com/test-icon.jpg")!
    mockImageCache.mockImageURL = mockURL

    let store = ProfileSetupStore(
      member: testMember,
      memberUpdateClient: mockMemberUpdateClient,
      storageClient: mockStorageClient,
      imageCache: mockImageCache
    )

    // イメージURLが非同期で取得されるため、少し待機
    try? await Task.sleep(nanoseconds: 100_000_000)

    // iconPathとiconImageURLが設定されていることを確認
    XCTAssertEqual(store.iconPath, iconPath)
    XCTAssertEqual(store.iconImageURL, mockURL)

    // Act
    store.send(ProfileSetupStore.Action.removeIcon)

    // Assert
    XCTAssertNil(store.iconPath)
    XCTAssertNil(store.iconImageURL)
    XCTAssertNil(store.selectedIconURL)
  }

  func testSaveButtonTappedAfterRemovingIcon() async {
    // Arrange
    let iconPath = "members/test-id/icons/test-icon.jpg"
    let testMember = Member(
      id: "test-id",
      name: "Test User",
      icon: iconPath,
      createdAt: Date(),
      updatedAt: Date()
    )

    let store = ProfileSetupStore(
      member: testMember,
      memberUpdateClient: mockMemberUpdateClient,
      storageClient: mockStorageClient,
      imageCache: mockImageCache
    )
    store.delegate = mockDelegate

    // アイコンを削除
    store.send(ProfileSetupStore.Action.removeIcon)

    // 保存
    store.send(ProfileSetupStore.Action.saveButtonTapped)

    // 非同期処理が完了するのを待つ
    try? await Task.sleep(nanoseconds: 100_000_000)

    // Assert
    XCTAssertTrue(mockMemberUpdateClient.updateProfileWasCalled)
    XCTAssertEqual(mockMemberUpdateClient.updatedProfileMemberID, testMember.id)
    XCTAssertEqual(mockMemberUpdateClient.updatedProfileName, "Test User")
    XCTAssertNil(mockMemberUpdateClient.updatedProfileIconPath)
    XCTAssertFalse(store.isLoading)
    XCTAssertTrue(mockDelegate.didCompleteProfileSetupCalled)
  }
}
