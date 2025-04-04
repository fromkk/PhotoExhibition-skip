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

  private let currentUserClient: any CurrentUserClient
  private let membersClient: any MembersClient
  private let analyticsClient: any AnalyticsClient

  var member: Member?
  let deviceInfo: any DeviceInfo

  // プロフィール編集画面用のストア
  var profileSetupStore: ProfileSetupStore?
  // マイ展示会画面用のストア
  var myExhibitionsStore: MyExhibitionsStore?
  // 問い合わせ画面用のストア
  var contactStore: ContactStore?
  // ブロックユーザー一覧画面用のストア
  var blockedUsersStore: BlockedUsersStore?
  #if !SKIP
    // ライセンス画面のストア
    var licenseStore: LicenseListStore?
  #endif

  init(
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    membersClient: any MembersClient = DefaultMembersClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient(),
    deviceInfo: any DeviceInfo = DefaultDeviceInfo()
  ) {
    self.currentUserClient = currentUserClient
    self.membersClient = membersClient
    self.analyticsClient = analyticsClient
    self.deviceInfo = deviceInfo
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
    case contactButtonTapped
    case blockedUsersButtonTapped
    #if !SKIP
      case licenseButtonTapped
    #endif
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
        await analyticsClient.analyticsScreen(name: "SettingsView")
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
    case .profileEditCompleted:
      profileSetupStore = nil
      Task {
        await fetchMember()
      }
    case .myExhibitionsButtonTapped:
      myExhibitionsStore = MyExhibitionsStore()
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
    case .contactButtonTapped:
      contactStore = ContactStore()
    case .blockedUsersButtonTapped:
      blockedUsersStore = BlockedUsersStore()
    #if !SKIP
      case .licenseButtonTapped:
        licenseStore = LicenseListStore()
    #endif
    }
  }

  // MARK: - ProfileSetupStoreDelegate

  func didCompleteProfileSetup() {
    send(.profileEditCompleted)
  }

  private func fetchMember() async {
    guard let user = currentUserClient.currentUser() else {
      return
    }

    do {
      let uids = [user.uid]
      let members = try await membersClient.fetch(uids)
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
  @Environment(\.openURL) private var openURL

  var body: some View {
    List {
      Section {
        if let member = store.member {
          Button {
            store.send(.editProfileButtonTapped)
          } label: {
            HStack {
              if let iconPath = member.iconPath {
                AsyncImageWithIconPath(iconPath: iconPath)
              } else {
                Image(
                  systemName: SystemImageMapping.getIconName(
                    from: "person.crop.circle.fill"
                  )
                )
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
            .frame(maxWidth: .infinity, alignment: .leading)
            #if !SKIP
              .contentShape(Rectangle())
            #endif
          }
          .buttonStyle(.plain)
        }

        Button {
          store.send(.myExhibitionsButtonTapped)
        } label: {
          HStack {
            #if SKIP
              Image("photo.on.rectangle", bundle: .module)
                .frame(width: 24, height: 24)
            #else
              Image(systemName: "photo.on.rectangle")
                .frame(width: 24, height: 24)
            #endif
            Text("My Exhibitions")
              .padding(.leading, 8)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          #if !SKIP
            .contentShape(Rectangle())
          #endif
        }
        .buttonStyle(.plain)

        Button {
          store.send(.blockedUsersButtonTapped)
        } label: {
          HStack {
            Text("Blocked Users")
              .padding(.leading, 8)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          #if !SKIP
            .contentShape(Rectangle())
          #endif
        }
        .buttonStyle(.plain)
      }

      Section {
        Button {
          store.send(.contactButtonTapped)
        } label: {
          HStack {
            Text("Contact")
              .padding(.leading, 8)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          #if !SKIP
            .contentShape(Rectangle())
          #endif
        }
        .buttonStyle(.plain)

        Button {
          openURL(Constants.termsOfServiceURL)
        } label: {
          HStack {
            Text("Terms of Service")
              .padding(.leading, 8)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          #if !SKIP
            .contentShape(Rectangle())
          #endif
        }
        .buttonStyle(.plain)

        Button {
          openURL(Constants.privacyPolicyURL)
        } label: {
          HStack {
            Text("Privacy Policy")
              .padding(.leading, 8)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          #if !SKIP
            .contentShape(Rectangle())
          #endif
        }
        .buttonStyle(.plain)

        #if !SKIP
          Button {
            store.send(.licenseButtonTapped)
          } label: {
            HStack {
              Text("Licenses")
                .padding(.leading, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        #endif
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
      } footer: {
        if let version = store.deviceInfo.appVersion,
          let buildNumber = store.deviceInfo.buildNumber
        {
          Text("\(version) (\(buildNumber))")
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .center)
        }
      }
    }
    .navigationTitle(Text("Settings"))
    .sheet(
      isPresented: Binding(
        get: { store.profileSetupStore != nil },
        set: { if !$0 { store.profileSetupStore = nil } }
      )
    ) {
      if let profileSetupStore = store.profileSetupStore {
        NavigationStack {
          ProfileSetupView(store: profileSetupStore)
            .navigationTitle(Text("Edit Profile"))
        }
      }
    }
    .navigationDestination(
      isPresented: Binding(
        get: { store.myExhibitionsStore != nil },
        set: { if !$0 { store.myExhibitionsStore = nil } }
      )
    ) {
      if let myExhibitionsStore = store.myExhibitionsStore {
        MyExhibitionsView(store: myExhibitionsStore)
          .navigationTitle(Text("My Exhibitions"))
      }
    }
    .navigationDestination(
      isPresented: Binding(
        get: { store.contactStore != nil },
        set: { if !$0 { store.contactStore = nil } }
      )
    ) {
      if let contactStore = store.contactStore {
        ContactView(store: contactStore)
      }
    }
    .navigationDestination(
      isPresented: Binding(
        get: { store.blockedUsersStore != nil },
        set: { if !$0 { store.blockedUsersStore = nil } }
      )
    ) {
      if let blockedUsersStore = store.blockedUsersStore {
        BlockedUsersView(store: blockedUsersStore)
          .navigationTitle(Text("Blocked Users"))
      }
    }
    #if !SKIP
      .navigationDestination(
        isPresented: Binding(
          get: { store.licenseStore != nil },
          set: { if !$0 { store.licenseStore = nil } }
        ),
        destination: {
          if let store = store.licenseStore {
            LicenseListView(store: store)
          }
        }
      )
    #endif
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
        Text(
          "This action cannot be undone. All your data will be permanently deleted."
        )
      }
    )
  }
}

/// アイコンパスからURLを非同期に取得して画像を表示するコンポーネント
private struct AsyncImageWithIconPath: View {
  let iconPath: String
  @State private var iconURL: URL? = nil
  @State private var isLoading: Bool = true
  private let imageCache: any StorageImageCacheProtocol = StorageImageCache
    .shared

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
