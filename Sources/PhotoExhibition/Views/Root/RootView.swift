import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class RootStore: Store, AuthStoreDelegate, SettingsStoreDelegate, ProfileSetupStoreDelegate {
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
    case signInButtonTapped
    case signUpButtonTapped
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
  // Updated flags for signIn and signUp screen display
  var isSignInScreenShown: Bool = false {
    didSet {
      if isSignInScreenShown {
        authStore = AuthStore(authMode: .signIn)
        authStore?.delegate = self
      } else {
        authStore = nil
      }
    }
  }
  var isSignUpScreenShown: Bool = false {
    didSet {
      if isSignUpScreenShown {
        authStore = AuthStore(authMode: .signUp)
        authStore?.delegate = self
      } else {
        authStore = nil
      }
    }
  }

  var isProfileSetupShown: Bool = false

  private(set) var authStore: AuthStore?
  private(set) var exhibitionsStore: ExhibitionsStore?
  private(set) var settingsStore: SettingsStore?
  private(set) var profileSetupStore: ProfileSetupStore?

  func send(_ action: Action) {
    switch action {
    case .task:
      if let currentUser = currentUserClient.currentUser() {
        // ユーザーがログインしているが、Memberを取得する必要がある場合
        Task {
          do {
            let members = try await membersClient.fetch([currentUser.uid])
            if let member = members.first {
              isSignedIn = true

              // メンバー名が設定されていない場合はプロフィール設定画面を表示
              if member.name == nil {
                showProfileSetup(for: member)
              }
            } else {
              // メンバー情報が取得できなかった場合
              isSignedIn = false
            }
          } catch {
            print("Failed to fetch member: \(error.localizedDescription)")
            isSignedIn = false
          }
        }
      } else {
        isSignedIn = false
      }
    case .signInButtonTapped:
      isSignInScreenShown = true
      return
    case .signUpButtonTapped:
      isSignUpScreenShown = true
      return
    }
  }

  // MARK: - AuthStoreDelegate

  func didSignInSuccessfully(with member: Member) {
    isSignInScreenShown = false
    isSignUpScreenShown = false
    isSignedIn = true

    // Show profile setup screen if member name is not set
    if member.name == nil {
      showProfileSetup(for: member)
    }
  }

  // MARK: - SettingsStoreDelegate

  func logoutCompleted() {
    isSignedIn = false
  }

  func deleteAccountCompleted() {
    isSignedIn = false
  }

  // MARK: - ProfileSetupStoreDelegate

  func didCompleteProfileSetup() {
    isProfileSetupShown = false
    profileSetupStore = nil
  }

  // MARK: - Helper Methods

  private func showProfileSetup(for member: Member) {
    let store = ProfileSetupStore(member: member)
    store.delegate = self
    profileSetupStore = store
    isProfileSetupShown = true
  }
}

struct RootView: View {
  @Bindable var store = RootStore()
  var body: some View {
    Group {
      if store.isSignedIn {
        if store.isProfileSetupShown, let profileSetupStore = store.profileSetupStore {
          // Display profile setup screen
          NavigationStack {
            ProfileSetupView(store: profileSetupStore)
              .navigationTitle("Profile Setup")
              .navigationBarBackButtonHidden(true)
          }
        } else {
          // Display main screen (tab view)
          TabView {
            if let exhibitionsStore = store.exhibitionsStore {
              NavigationStack {
                ExhibitionsView(store: exhibitionsStore)
              }
              .tabItem {
                #if SKIP
                  Image("photo", bundle: .module)
                  Text("Exhibitions")
                #else
                  Label("Exhibitions", systemImage: "photo")
                #endif
              }
            }

            if let settingsStore = store.settingsStore {
              NavigationStack {
                SettingsView(store: settingsStore)
              }
              .tabItem {
                Label("Settings", systemImage: SystemImageMapping.getIconName(from: "gear"))
              }
            }
          }
        }
      } else {
        TopView(store: store)
      }
    }
    .background(Color("background", bundle: .module))
    .task {
      store.send(.task)
    }
  }
}

#Preview {
  RootView()
}
