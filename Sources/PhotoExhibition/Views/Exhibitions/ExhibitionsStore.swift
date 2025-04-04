import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class ExhibitionsStore: Store, ExhibitionEditStoreDelegate {
  enum Action {
    case task
    case refresh
    case createExhibitionButtonTapped
    case editExhibition(Exhibition)
    case showExhibitionDetail(Exhibition)
    case loadMore
    case exhibitionCreated(Exhibition)
    case exhibitionUpdated(Exhibition)
    case postAgreementAccepted
    case postAgreementDismissed
  }

  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  var exhibitionToEdit: Exhibition? = nil
  private var nextCursor: String? = nil
  var hasMore: Bool = true

  var isLoadingMember: Bool = false

  // 選択された展示会の詳細画面用のストアを保持
  var exhibitionDetailStore: ExhibitionDetailStore?
  // 展示会編集画面用のストアを保持
  var exhibitionEditStore: ExhibitionEditStore?

  // PostAgreement表示用の状態
  var showPostAgreement: Bool = false

  private let exhibitionsClient: any ExhibitionsClient
  private let currentUserClient: any CurrentUserClient
  private let membersClient: any MembersClient
  private let memberUpdateClient: any MemberUpdateClient
  private let storageClient: any StorageClient
  private let imageCache: any StorageImageCacheProtocol
  private let photoClient: any PhotoClient
  private let analyticsClient: any AnalyticsClient

  init(
    exhibitionsClient: any ExhibitionsClient = DefaultExhibitionsClient(),
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    membersClient: any MembersClient = DefaultMembersClient(),
    memberUpdateClient: any MemberUpdateClient = DefaultMemberUpdateClient(),
    storageClient: any StorageClient = DefaultStorageClient(),
    imageCache: any StorageImageCacheProtocol = StorageImageCache.shared,
    photoClient: any PhotoClient = DefaultPhotoClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.exhibitionsClient = exhibitionsClient
    self.currentUserClient = currentUserClient
    self.membersClient = membersClient
    self.memberUpdateClient = memberUpdateClient
    self.storageClient = storageClient
    self.imageCache = imageCache
    self.photoClient = photoClient
    self.analyticsClient = analyticsClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      guard !isLoading else { return }
      fetchExhibitions()
      Task {
        await analyticsClient.analyticsScreen(name: "ExhibitionsView")
      }
    case .refresh:
      fetchExhibitions()
    case .createExhibitionButtonTapped:
      guard let uid = currentUserClient.currentUser()?.uid else {
        return
      }
      isLoadingMember = true
      Task {
        do {
          let uids = [uid]
          let result = try await membersClient.fetch(uids)
          isLoadingMember = false
          guard let member = result.first else {
            return
          }

          if member.postAgreement {
            showCreateExhibitionView()
          } else {
            withAnimation {
              showPostAgreement = true
            }
          }
        } catch {
          self.error = error
        }
      }

    case .editExhibition(let exhibition):
      exhibitionEditStore = ExhibitionEditStore(
        mode: .edit(exhibition),
        delegate: self,
        currentUserClient: currentUserClient,
        exhibitionsClient: exhibitionsClient,
        storageClient: storageClient,
        imageCache: imageCache
      )
      exhibitionToEdit = exhibition
    case .showExhibitionDetail(let exhibition):
      exhibitionDetailStore = ExhibitionDetailStore(
        exhibition: exhibition,
        exhibitionsClient: exhibitionsClient,
        currentUserClient: currentUserClient,
        storageClient: storageClient,
        imageCache: imageCache,
        photoClient: photoClient
      )
    case .loadMore:
      if !isLoading && hasMore {
        fetchMoreExhibitions()
      }
    case .exhibitionCreated(let exhibition):
      exhibitions.insert(exhibition, at: 0)
      exhibitionEditStore = nil
    case .exhibitionUpdated(let exhibition):
      if let index = exhibitions.firstIndex(where: { $0.id == exhibition.id }) {
        exhibitions[index] = exhibition
      }
      exhibitionToEdit = nil
      exhibitionEditStore = nil
    case .postAgreementAccepted:
      withAnimation {
        showPostAgreement = false
      }
      guard let uid = currentUserClient.currentUser()?.uid else {
        return
      }
      Task {
        do {
          _ = try await memberUpdateClient.postAgreement(memberID: uid)
          showCreateExhibitionView()
        } catch {
          self.error = error
        }
      }
    case .postAgreementDismissed:
      withAnimation {
        showPostAgreement = false
      }
    }
  }

  @MainActor
  private func showCreateExhibitionView() {
    exhibitionEditStore = ExhibitionEditStore(
      mode: .create,
      delegate: self,
      currentUserClient: currentUserClient,
      exhibitionsClient: exhibitionsClient,
      storageClient: storageClient,
      imageCache: imageCache
    )
  }

  // MARK: - ExhibitionEditStoreDelegate

  func didSaveExhibition() {
    send(.refresh)
  }

  func didCancelExhibition() {
    exhibitionEditStore = nil
    exhibitionToEdit = nil
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

  func showExhibitionDetail(exhibitionId: String) {
    Task {
      do {
        // 展示会の詳細を取得
        let exhibition = try await exhibitionsClient.get(id: exhibitionId)

        // 展示が非公開の場合は何もしない
        guard exhibition.status == .published else {
          print("Exhibition is not published: \(exhibitionId)")
          return
        }

        // 展示の期間外の場合は何もしない
        let now = Date()
        guard exhibition.from <= now && now <= exhibition.to else {
          print("Exhibition is not active: \(exhibitionId)")
          return
        }

        // メインスレッドで展示会の詳細画面を表示
        await MainActor.run {
          exhibitionDetailStore = ExhibitionDetailStore(
            exhibition: exhibition,
            exhibitionsClient: exhibitionsClient,
            currentUserClient: currentUserClient,
            storageClient: storageClient,
            imageCache: imageCache,
            photoClient: photoClient
          )
        }
      } catch {
        print("Failed to fetch exhibition: \(error.localizedDescription)")
      }
    }
  }
}
