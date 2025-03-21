import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class RootStore: Store {
  private let currentUserClient: CurrentUserClient
  private let membersClient: MembersClient

  init(
    currentUserClient: CurrentUserClient = DefaultCurrentUserClient(),
    membersClient: MembersClient = DefaultMembersClient()
  ) {
    self.currentUserClient = currentUserClient
    self.membersClient = membersClient
  }

  enum Action: Sendable {
    case task
    case signedIn(Member)
    case signedOut
  }

  private(set) var isSignedIn: Bool = false {
    didSet {
      if isSignedIn {
        exhibitionsStore = ExhibitionsStore()
        settingsStore = SettingsStore()
        settingsStore?.delegate = self
      } else {
        exhibitionsStore = nil
        settingsStore = nil
        profileSetupStore = nil
      }
    }
  }

  var isProfileSetupShown: Bool = false

  private(set) var exhibitionsStore: ExhibitionsStore?
  private(set) var settingsStore: SettingsStore?
  private(set) var profileSetupStore: ProfileSetupStore?

  func send(_ action: Action) {
    switch action {
    case .task:
      if let currentUser = currentUserClient.currentUser() {
        Task {
          do {
            let uids: [any Sendable] = [currentUser.uid]
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
        }
      } else {
        isSignedIn = false
      }
    case let .signedIn(member):
      isSignedIn = true
      if member.name == nil {
        showProfileSetup(for: member)
      }
    case .signedOut:
      isSignedIn = false
    }
  }

  private func showProfileSetup(for member: Member) {
    let store = ProfileSetupStore(member: member)
    store.delegate = self
    profileSetupStore = store
    isProfileSetupShown = true
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
    isProfileSetupShown = false
    profileSetupStore = nil
  }
}

extension RootStore: AuthRootStoreDelegate {
  func didSignInSuccessfully(with member: Member) {
    send(.signedIn(member))
  }
}
