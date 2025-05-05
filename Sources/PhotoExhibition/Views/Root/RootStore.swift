import PhotoExhibitionModel
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class RootStore: Store {
  private let currentUserClient: any CurrentUserClient
  private let membersClient: any MembersClient
  private let analyticsClient: any AnalyticsClient

  init(
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    membersClient: any MembersClient = DefaultMembersClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.currentUserClient = currentUserClient
    self.membersClient = membersClient
    self.analyticsClient = analyticsClient
  }

  enum Action: Sendable {
    case task
    case signedIn(Member)
    case signedOut
    case handleUniversalLink(URL)
    case addExhibitionRequestReceived
  }

  var isSignedIn: Bool = false {
    didSet {
      if isSignedIn {
        // クライアントの生成
        let exhibitionsClient = DefaultExhibitionsClient(
          blockClient: DefaultBlockClient.shared,
          currentUserClient: DefaultCurrentUserClient()
        )

        exhibitionsStore = ExhibitionsStore(exhibitionsClient: exhibitionsClient)
        settingsStore = SettingsStore()
        settingsStore?.delegate = self
      } else {
        exhibitionsStore = nil
        settingsStore = nil
        profileSetupStore = nil
      }
    }
  }

  var selectedTab: Tab = .exhibitions

  var exhibitionsStore: ExhibitionsStore?
  var settingsStore: SettingsStore?
  var profileSetupStore: ProfileSetupStore?
  private var pendingUniversalLink: URL?
  private var pendingAddExhibitionRequestReceived: Bool = false

  func send(_ action: Action) {
    switch action {
    case .task:
      if let currentUser = currentUserClient.currentUser() {
        Task {
          do {
            let uids = [currentUser.uid]
            let members = try await membersClient.fetch(uids)
            if let member = members.first {
              await MainActor.run {
                self.send(.signedIn(member))
              }
            }
          } catch {
            print("Failed to fetch member: \(error.localizedDescription)")
            isSignedIn = false
          }
          await analyticsClient.analyticsScreen(name: "RootView")
        }
      } else {
        isSignedIn = false
      }
    case let .signedIn(member):
      isSignedIn = true
      if member.name == nil {
        showProfileSetup(for: member)
      } else if let url = pendingUniversalLink {
        handleOpenURL(url)
        pendingUniversalLink = nil
      } else if pendingAddExhibitionRequestReceived {
        showAddExhibition()
        pendingAddExhibitionRequestReceived = false
      }
    case .signedOut:
      isSignedIn = false
      pendingUniversalLink = nil
    case .handleUniversalLink(let url):
      if isSignedIn {
        handleOpenURL(url)
      } else {
        pendingUniversalLink = url
      }
    case .addExhibitionRequestReceived:
      if isSignedIn {
        showAddExhibition()
      } else {
        pendingAddExhibitionRequestReceived = true
      }
    }
  }

  private func handleOpenURL(_ url: URL) {
    guard isSignedIn else { return }

    if url.scheme == "exhivision" {
      // Custom url scheme
      // URLのパスを解析
      if url.host() == "add_exhibition" {
        showAddExhibition()
      } else {
        let pathComponents = url.pathComponents
        guard pathComponents.count == 2 && url.host() == "exhibition" else { return }

        // exhibitionIdを取得
        let exhibitionId = pathComponents[1]

        // 展示タブを選択
        selectedTab = .exhibitions

        // ExhibitionsStoreに展示会の表示を要求
        exhibitionsStore?.showExhibitionDetail(exhibitionId: exhibitionId)
      }
    } else {
      // URLのパスを解析
      let pathComponents = url.pathComponents
      guard pathComponents.count == 3 && pathComponents[1] == "exhibition" else { return }

      // exhibitionIdを取得
      let exhibitionId = pathComponents[2]

      // 展示タブを選択
      selectedTab = .exhibitions

      // ExhibitionsStoreに展示会の表示を要求
      exhibitionsStore?.showExhibitionDetail(exhibitionId: exhibitionId)
    }
  }

  private func showProfileSetup(for member: Member) {
    let store = ProfileSetupStore(member: member)
    store.delegate = self
    profileSetupStore = store
  }

  private func showAddExhibition() {
    exhibitionsStore?.send(.createExhibitionButtonTapped)
  }
}

extension RootStore: SettingsStoreDelegate {
  func logoutCompleted() {
    send(.signedOut)
  }

  func deleteAccountCompleted() {
    send(.signedOut)
  }
}

extension RootStore: ProfileSetupStoreDelegate {
  func didCompleteProfileSetup() {
    profileSetupStore = nil
  }
}

extension RootStore: AuthRootStoreDelegate {
  func didSignInSuccessfully(with member: Member) {
    send(.signedIn(member))
  }
}

enum Tab {
  case exhibitions
  case settings
}
