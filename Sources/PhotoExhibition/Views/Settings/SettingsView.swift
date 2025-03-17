import SkipWeb
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@MainActor
protocol SettingsStoreDelegate: AnyObject {
  func logoutCompleted()
  func deleteAccountCompleted()
}

@Observable final class SettingsStore: Store, ProfileSetupStoreDelegate {
  weak var delegate: (any SettingsStoreDelegate)?

  private let currentUserClient: CurrentUserClient
  private let membersClient: MembersClient

  var member: Member?
  var isProfileEditPresented: Bool = false
  var showMyExhibitions: Bool = false
  var showTermsOfService: Bool = false
  var showPrivacyPolicy: Bool = false

  // プロフィール編集画面用のストア
  private(set) var profileSetupStore: ProfileSetupStore?
  // マイ展示会画面用のストア
  private(set) var myExhibitionsStore: MyExhibitionsStore?

  init(
    currentUserClient: CurrentUserClient = DefaultCurrentUserClient(),
    membersClient: MembersClient = DefaultMembersClient()
  ) {
    self.currentUserClient = currentUserClient
    self.membersClient = membersClient
  }

  enum Action {
    case task
    case logoutButtonTapped
    case presentLogoutConfirmation
    case editProfileButtonTapped
    case profileEditCompleted
    case myExhibitionsButtonTapped
    case deleteAccountButtonTapped
    case presentDeleteAccountConfirmation
    case termsOfServiceButtonTapped
    case privacyPolicyButtonTapped
  }

  var isErrorAlertPresented: Bool = false
  var error: (any Error)?
  var isLogoutConfirmationPresented: Bool = false
  var isDeleteAccountConfirmationPresented: Bool = false

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        await fetchMember()
      }
    case .logoutButtonTapped:
      do {
        try currentUserClient.logout()
        delegate?.logoutCompleted()
      } catch {
        self.error = error
        isErrorAlertPresented = true
      }
    case .presentLogoutConfirmation:
      isLogoutConfirmationPresented = true
    case .editProfileButtonTapped:
      if let member = member {
        profileSetupStore = ProfileSetupStore(member: member)
        profileSetupStore?.delegate = self
      }
      isProfileEditPresented = true
    case .profileEditCompleted:
      isProfileEditPresented = false
      profileSetupStore = nil
    case .myExhibitionsButtonTapped:
      myExhibitionsStore = MyExhibitionsStore()
      showMyExhibitions = true
    case .deleteAccountButtonTapped:
      Task { @MainActor in
        do {
          try await currentUserClient.deleteAccount()
          delegate?.deleteAccountCompleted()
        } catch {
          self.error = error
          isErrorAlertPresented = true
        }
      }
    case .presentDeleteAccountConfirmation:
      isDeleteAccountConfirmationPresented = true
    case .termsOfServiceButtonTapped:
      showTermsOfService = true
    case .privacyPolicyButtonTapped:
      showPrivacyPolicy = true
    }
  }

  // MARK: - ProfileSetupStoreDelegate

  func didCompleteProfileSetup() {
    send(.profileEditCompleted)
    Task {
      await fetchMember()
    }
  }

  private func fetchMember() async {
    guard let user = currentUserClient.currentUser() else {
      return
    }

    do {
      let members = try await membersClient.fetch([user.uid])
      if let fetchedMember = members.first {
        member = fetchedMember
      }
    } catch {
      self.error = error
      isErrorAlertPresented = true
    }
  }
}

struct SettingsView: View {
  @Bindable var store: SettingsStore
  var body: some View {
    List {
      Section {
        if let member = store.member {
          Button {
            store.send(.editProfileButtonTapped)
          } label: {
            HStack {
              if let iconPath = member.icon {
                AsyncImageWithIconPath(iconPath: iconPath)
              } else {
                Image(systemName: "person.crop.circle.fill")
                  .resizable()
                  .frame(width: 40, height: 40)
                  .foregroundStyle(Color.gray)
              }

              Text("Edit Profile")
                .padding(.leading, 8)
              Spacer()
              Text(member.name ?? "Not set")
                .foregroundStyle(.secondary)
            }
          }
          .buttonStyle(.plain)
        }
      }

      Section {
        Button {
          store.send(.myExhibitionsButtonTapped)
        } label: {
          HStack {
            Image(systemName: "photo.on.rectangle")
              .frame(width: 24, height: 24)
            Text("My Exhibitions")
              .padding(.leading, 8)
          }
        }
        .buttonStyle(.plain)
      }

      Section {
        Button {
          store.send(.termsOfServiceButtonTapped)
        } label: {
          HStack {
            Image(systemName: "doc.text")
              .frame(width: 24, height: 24)
            Text("Terms of Service")
              .padding(.leading, 8)
          }
        }
        .buttonStyle(.plain)

        Button {
          store.send(.privacyPolicyButtonTapped)
        } label: {
          HStack {
            Image(systemName: "lock.doc")
              .frame(width: 24, height: 24)
            Text("Privacy Policy")
              .padding(.leading, 8)
          }
        }
        .buttonStyle(.plain)
      }

      Section {
        Button(role: .destructive) {
          store.send(.presentLogoutConfirmation)
        } label: {
          Text("Logout")
        }

        Button(role: .destructive) {
          store.send(.presentDeleteAccountConfirmation)
        } label: {
          Text("Delete Account")
        }
      }
    }
    .navigationTitle(Text("Settings"))
    .navigationDestination(isPresented: $store.isProfileEditPresented) {
      if let profileSetupStore = store.profileSetupStore {
        ProfileSetupView(store: profileSetupStore)
          .navigationTitle("Edit Profile")
      }
    }
    .navigationDestination(isPresented: $store.showMyExhibitions) {
      if let myExhibitionsStore = store.myExhibitionsStore {
        MyExhibitionsView(store: myExhibitionsStore)
          .navigationTitle("My Exhibitions")
      }
    }
    .navigationDestination(isPresented: $store.showTermsOfService) {
      WebView(url: Constants.termsOfServiceURL)
    }
    .navigationDestination(isPresented: $store.showPrivacyPolicy) {
      WebView(url: Constants.privacyPolicyURL)
    }
    .task {
      store.send(.task)
    }
    .alert(
      "Error",
      isPresented: $store.isErrorAlertPresented,
      actions: {
        Button("OK") {}
      },
      message: {
        Text(store.error?.localizedDescription ?? "Unknown error")
      }
    )
    .alert(
      "Are you sure you want to log out?",
      isPresented: $store.isLogoutConfirmationPresented,
      actions: {
        Button("Cancel", role: .cancel) {}
        Button("Yes", role: .destructive) {
          store.send(.logoutButtonTapped)
        }
      }
    )
    .alert(
      "Are you sure you want to delete your account?",
      isPresented: $store.isDeleteAccountConfirmationPresented,
      actions: {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
          store.send(.deleteAccountButtonTapped)
        }
      },
      message: {
        Text("This action cannot be undone. All your data will be permanently deleted.")
      }
    )
  }
}

/// アイコンパスからURLを非同期に取得して画像を表示するコンポーネント
private struct AsyncImageWithIconPath: View {
  let iconPath: String
  @State private var iconURL: URL? = nil
  @State private var isLoading: Bool = true
  private let imageCache: any StorageImageCacheProtocol = StorageImageCache.shared

  var body: some View {
    AsyncImage(url: iconURL) { image in
      image
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    } placeholder: {
      ZStack {
        Circle()
          .fill(Color.gray.opacity(0.2))
          .frame(width: 40, height: 40)

        if isLoading {
          ProgressView()
            .frame(width: 40, height: 40)
        }
      }
    }
    .task {
      isLoading = true
      do {
        iconURL = try await imageCache.getImageURL(for: iconPath)
      } catch {
        print("Failed to load icon image: \(error.localizedDescription)")
      }
      isLoading = false
    }
  }
}
