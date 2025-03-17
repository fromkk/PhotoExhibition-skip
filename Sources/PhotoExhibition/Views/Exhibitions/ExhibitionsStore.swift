import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class ExhibitionsStore: Store {
  enum Action {
    case task
    case refresh
    case createExhibition
    case editExhibition(Exhibition)
    case showExhibitionDetail(Exhibition)
    case loadMore
  }

  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  var showCreateExhibition: Bool = false
  var exhibitionToEdit: Exhibition? = nil
  private var nextCursor: String? = nil
  var hasMore: Bool = true

  // 選択された展示会の詳細画面用のストアを保持
  private(set) var exhibitionDetailStore: ExhibitionDetailStore?
  // 詳細画面への遷移状態
  var isExhibitionDetailShown: Bool = false

  private let exhibitionsClient: ExhibitionsClient
  private let currentUserClient: CurrentUserClient
  private let storageClient: StorageClient
  private let imageCache: StorageImageCacheProtocol
  private let photoClient: PhotoClient

  init(
    exhibitionsClient: ExhibitionsClient = DefaultExhibitionsClient(),
    currentUserClient: CurrentUserClient = DefaultCurrentUserClient(),
    storageClient: StorageClient = DefaultStorageClient(),
    imageCache: StorageImageCacheProtocol = StorageImageCache.shared,
    photoClient: PhotoClient = DefaultPhotoClient()
  ) {
    self.exhibitionsClient = exhibitionsClient
    self.currentUserClient = currentUserClient
    self.storageClient = storageClient
    self.imageCache = imageCache
    self.photoClient = photoClient
  }

  func send(_ action: Action) {
    switch action {
    case .task, .refresh:
      fetchExhibitions()
    case .createExhibition:
      showCreateExhibition = true
    case .editExhibition(let exhibition):
      exhibitionToEdit = exhibition
    case .showExhibitionDetail(let exhibition):
      exhibitionDetailStore = createExhibitionDetailStore(for: exhibition)
      isExhibitionDetailShown = true
    case .loadMore:
      if !isLoading && hasMore {
        fetchMoreExhibitions()
      }
    }
  }

  // 展示会詳細画面用のストアを作成するメソッド
  private func createExhibitionDetailStore(for exhibition: Exhibition) -> ExhibitionDetailStore {
    return ExhibitionDetailStore(
      exhibition: exhibition,
      exhibitionsClient: exhibitionsClient,
      currentUserClient: currentUserClient,
      storageClient: storageClient,
      imageCache: imageCache,
      photoClient: photoClient
    )
  }

  private func fetchExhibitions() {
    isLoading = true
    exhibitions = []
    nextCursor = nil
    hasMore = true

    Task {
      do {
        let result = try await exhibitionsClient.fetch(now: Date(), cursor: nil)
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
    guard let cursor = nextCursor else { return }

    isLoading = true

    Task {
      do {
        let result = try await exhibitionsClient.fetch(now: Date(), cursor: cursor)
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
