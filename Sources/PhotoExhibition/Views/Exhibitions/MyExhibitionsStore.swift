import PhotoExhibitionModel
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class MyExhibitionsStore: Store, ExhibitionEditStoreDelegate {
  enum Action {
    case task
    case refresh
    case loadMore
    case addButtonTapped
    case exhibitionSelected(Exhibition)
    case postAgreementAccepted
    case postAgreementDismissed
  }

  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  private var nextCursor: String? = nil
  var hasMore: Bool = true

  var isLoadingMember: Bool = false
  var showPostAgreement: Bool = false

  private let exhibitionsClient: any ExhibitionsClient
  private let currentUserClient: any CurrentUserClient
  private let membersClient: any MembersClient
  private let memberUpdateClient: any MemberUpdateClient
  private let analyticsClient: any AnalyticsClient

  var exhibitionDetailStore: ExhibitionDetailStore?

  var exhibitionEditStore: ExhibitionEditStore?

  init(
    exhibitionsClient: any ExhibitionsClient = DefaultExhibitionsClient(),
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    membersClient: any MembersClient = DefaultMembersClient(),
    memberUpdateClient: any MemberUpdateClient = DefaultMemberUpdateClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.exhibitionsClient = exhibitionsClient
    self.currentUserClient = currentUserClient
    self.membersClient = membersClient
    self.memberUpdateClient = memberUpdateClient
    self.analyticsClient = analyticsClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      fetchMyExhibitions()
      Task {
        await analyticsClient.analyticsScreen(name: "MyExhibitionsView")
      }
    case .refresh:
      fetchMyExhibitions()
    case .loadMore:
      if !isLoading && hasMore {
        fetchMoreExhibitions()
      }
    case let .exhibitionSelected(exhibition):
      exhibitionDetailStore = createExhibitionDetailStore(for: exhibition)
    case .addButtonTapped:
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
    exhibitionEditStore = ExhibitionEditStore(mode: .create, delegate: self)
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

  func didSaveExhibition() {
    fetchMyExhibitions()
  }

  func didCancelExhibition() {
    exhibitionEditStore = nil
  }
}
