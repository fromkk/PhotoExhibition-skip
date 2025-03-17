import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class MyExhibitionsStore: Store {
  enum Action {
    case task
    case refresh
    case loadMore
    case exhibitionSelected(Exhibition)
  }

  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  private var nextCursor: String? = nil
  var hasMore: Bool = true

  private let exhibitionsClient: ExhibitionsClient
  private let currentUserClient: CurrentUserClient

  var isExhibitionShown: Bool = false
  // 選択された展示会の詳細画面用のストアを保持
  private(set) var exhibitionDetailStore: ExhibitionDetailStore?

  init(
    exhibitionsClient: ExhibitionsClient = DefaultExhibitionsClient(),
    currentUserClient: CurrentUserClient = DefaultCurrentUserClient()
  ) {
    self.exhibitionsClient = exhibitionsClient
    self.currentUserClient = currentUserClient
  }

  func send(_ action: Action) {
    switch action {
    case .task, .refresh:
      fetchMyExhibitions()
    case .loadMore:
      if !isLoading && hasMore {
        fetchMoreExhibitions()
      }
    case let .exhibitionSelected(exhibition):
      exhibitionDetailStore = createExhibitionDetailStore(for: exhibition)
      isExhibitionShown = true
    }
  }

  // 展示会詳細画面用のストアを作成するメソッド
  private func createExhibitionDetailStore(for exhibition: Exhibition) -> ExhibitionDetailStore {
    return ExhibitionDetailStore(exhibition: exhibition)
  }

  private func fetchMyExhibitions() {
    guard let currentUser = currentUserClient.currentUser() else {
      return
    }

    isLoading = true
    exhibitions = []
    nextCursor = nil
    hasMore = true

    Task {
      do {
        let result = try await exhibitionsClient.fetchMyExhibitions(
          organizerID: currentUser.uid, cursor: nil)
        exhibitions = result.exhibitions
        nextCursor = result.nextCursor
        hasMore = result.nextCursor != nil
      } catch {
        self.error = error
      }

      isLoading = false
    }
  }

  private func fetchMoreExhibitions() {
    guard let cursor = nextCursor, let currentUser = currentUserClient.currentUser() else { return }

    isLoading = true

    Task {
      do {
        let result = try await exhibitionsClient.fetchMyExhibitions(
          organizerID: currentUser.uid, cursor: cursor)
        exhibitions.append(contentsOf: result.exhibitions)
        nextCursor = result.nextCursor
        hasMore = result.nextCursor != nil
      } catch {
        self.error = error
      }

      isLoading = false
    }
  }
}
