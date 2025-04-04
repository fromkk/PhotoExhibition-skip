import XCTest

@testable import PhotoExhibition

@MainActor
final class MyExhibitionsStoreTests: XCTestCase {
  private var mockExhibitionsClient: MockExhibitionsClient!
  private var mockCurrentUserClient: MockCurrentUserClient!
  private var mockMembersClient: MockMembersClient!
  private var mockMemberUpdateClient: MockMemberUpdateClient!
  private var mockAnalyticsClient: MockAnalyticsClient!

  override func setUp() async throws {
    mockExhibitionsClient = MockExhibitionsClient()
    mockCurrentUserClient = MockCurrentUserClient()
    mockMembersClient = MockMembersClient()
    mockMemberUpdateClient = MockMemberUpdateClient()
    mockAnalyticsClient = MockAnalyticsClient()
  }

  private func createStore() -> MyExhibitionsStore {
    return MyExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient,
      memberUpdateClient: mockMemberUpdateClient,
      analyticsClient: mockAnalyticsClient
    )
  }

  func testAddButtonTapped() async throws {
    let store = createStore()
    mockCurrentUserClient.mockUser = User(uid: "test-user")

    // ユーザーに投稿同意が既にある状態を設定
    let member = Member(
      id: "test-user", name: "Test User", icon: nil, postAgreement: true, createdAt: Date(),
      updatedAt: Date())
    try await mockMembersClient.addMockMember(member)

    store.send(MyExhibitionsStore.Action.addButtonTapped)

    try await Task.sleep(nanoseconds: 100_000_000)

    // 編集画面のStoreが作成されていることを確認
    XCTAssertNotNil(store.exhibitionEditStore)
  }

  // ... 他の既存のテスト ...
}
