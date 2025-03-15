import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@MainActor
protocol SettingsStoreDelegate: AnyObject {
  func logoutCompleted()
}

@Observable final class SettingsStore: Store, ProfileSetupStoreDelegate {
  weak var delegate: (any SettingsStoreDelegate)?

  private let currentUserClient: CurrentUserClient
  private let membersClient: MembersClient

  var member: Member?
  var isProfileEditPresented: Bool = false

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
  }

  var isErrorAlertPresented: Bool = false
  var error: (any Error)?
  var isLogoutConfirmationPresented: Bool = false

  func send(_ action: Action) {
    switch action {
    case .task:
      if let currentUser = currentUserClient.currentUser() {
        Task {
          do {
            let members = try await membersClient.fetch([currentUser.uid])
            if let member = members.first {
              self.member = member
            }
          } catch {
            print("Failed to fetch member: \(error.localizedDescription)")
            self.error = error
            self.isErrorAlertPresented = true
          }
        }
      }
    case .logoutButtonTapped:
      do {
        try currentUserClient.logout()
        delegate?.logoutCompleted()
      } catch {
        self.error = error
        self.isErrorAlertPresented = true
      }
    case .presentLogoutConfirmation:
      isLogoutConfirmationPresented = true
    case .editProfileButtonTapped:
      isProfileEditPresented = true
    case .profileEditCompleted:
      isProfileEditPresented = false
      // プロフィール編集後に再度ユーザー情報を取得
      send(.task)
    }
  }

  // MARK: - ProfileSetupStoreDelegate

  func didCompleteProfileSetup() {
    isProfileEditPresented = false
    // プロフィール更新後にユーザー情報を再取得
    send(.task)
  }
}

struct SettingsView: View {
  @Bindable var store: SettingsStore
  var body: some View {
    NavigationStack {
      List {
        Section {
          if let member = store.member {
            NavigationLink {
              let profileSetupStore = ProfileSetupStore(member: member)
              profileSetupStore.delegate = store
              return ProfileSetupView(store: profileSetupStore)
                .navigationTitle("Edit Profile")
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
          }
        }

        Section {
          Button(role: .destructive) {
            store.send(.presentLogoutConfirmation)
          } label: {
            Text("Logout")
          }
        }
      }
      .navigationTitle(Text("Settings"))
      .task {
        store.send(.task)
      }
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
