import SkipKit
import SwiftUI

#if canImport(Photos)
  import Photos
  import PhotosUI
#endif

#if canImport(Observation)
  import Observation
#endif

@MainActor
protocol ProfileSetupStoreDelegate: AnyObject {
  func didCompleteProfileSetup()
}

@Observable final class ProfileSetupStore: Store {
  enum Action {
    case saveButtonTapped
    case dismissError
    case selectIconButtonTapped
    case iconSelected(URL?)
    case removeIcon
  }

  let member: Member
  var name: String = ""
  weak var delegate: (any ProfileSetupStoreDelegate)?

  // アイコン関連
  var iconImageURL: URL?
  var iconPickerPresented: Bool = false
  var selectedIconURL: URL?
  var iconPath: String?

  // State management
  var isLoading: Bool = false
  var error: (any Error)?
  var isErrorAlertPresented: Bool = false

  private let memberUpdateClient: any MemberUpdateClient
  private let storageClient: StorageClient
  private let imageCache: any StorageImageCacheProtocol

  init(
    member: Member,
    memberUpdateClient: MemberUpdateClient = DefaultMemberUpdateClient(),
    storageClient: StorageClient = DefaultStorageClient(),
    imageCache: StorageImageCacheProtocol = StorageImageCache.shared
  ) {
    self.member = member
    self.memberUpdateClient = memberUpdateClient
    self.storageClient = storageClient
    self.imageCache = imageCache

    // Set initial value if existing name is available
    if let existingName = member.name {
      self.name = existingName
    }

    // 既存のアイコンがあれば表示用URLを取得
    if let iconPath = member.iconPath {
      self.iconPath = iconPath
      Task {
        do {
          self.iconImageURL = try await imageCache.getImageURL(for: iconPath)
        } catch {
          print("Failed to load icon image: \(error.localizedDescription)")
        }
      }
    }
  }

  func send(_ action: Action) {
    switch action {
    case .saveButtonTapped:
      isLoading = true
      error = nil
      isErrorAlertPresented = false

      Task {
        do {
          // アイコン画像が選択されていれば、先にアップロード
          var newIconPath = iconPath
          if let selectedIconURL = selectedIconURL {
            // 新しいファイルパスを生成
            let fileExtension =
              selectedIconURL.pathExtension.isEmpty ? "jpg" : selectedIconURL.pathExtension
            let path = "members/\(member.id)/icon.\(fileExtension)"

            // 画像をアップロード
            _ = try await storageClient.upload(from: selectedIconURL, to: path)
            newIconPath = path
          }

          // プロフィール情報を更新
          let updatedMember = try await memberUpdateClient.updateProfile(
            memberID: member.id, name: name, iconPath: newIconPath)
          print("Profile update success: \(updatedMember.id)")

          // アイコンパスが変更された場合、キャッシュをクリアする
          if newIconPath != member.icon {
            await imageCache.clearCache()
          }

          delegate?.didCompleteProfileSetup()
        } catch {
          self.error = error
          self.isErrorAlertPresented = true
          print("Profile update error: \(error.localizedDescription)")
        }

        isLoading = false
      }

    case .dismissError:
      isErrorAlertPresented = false

    case .selectIconButtonTapped:
      iconPickerPresented = true

    case .iconSelected(let url):
      selectedIconURL = url

    case .removeIcon:
      // 選択中のアイコンと既存のアイコンの両方をクリア
      selectedIconURL = nil
      iconPath = nil
      iconImageURL = nil
    }
  }
}

struct ProfileSetupView: View {
  @Bindable var store: ProfileSetupStore

  var body: some View {
    VStack(spacing: 32) {
      Text("Set Up Profile")
        .font(.title)
        .padding(.bottom, 8)

      Text("Please set a username and icon to continue using the app")
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      // アイコン表示とアイコン選択ボタン
      VStack(spacing: 16) {
        ZStack {
          Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 120, height: 120)

          if let iconURL = store.selectedIconURL ?? store.iconImageURL {
            AsyncImage(url: iconURL) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            } placeholder: {
              ProgressView()
                .frame(width: 120, height: 120)
            }
          } else if store.iconPath != nil {
            // iconPathが存在するがURLがまだ取得できていない場合はローディングを表示
            ProgressView()
              .frame(width: 120, height: 120)
          } else {
            Image(systemName: SystemImageMapping.getIconName(from: "person.crop.circle.fill"))
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 80, height: 80)
              .foregroundStyle(Color.gray)
          }
        }

        HStack(spacing: 20) {
          Button {
            store.send(.selectIconButtonTapped)
          } label: {
            Text("Select Icon")
              .foregroundStyle(.blue)
          }

          // アイコンが設定されているか選択されている場合のみ削除ボタンを表示
          if store.selectedIconURL != nil || store.iconImageURL != nil {
            Button(role: .destructive) {
              store.send(.removeIcon)
            } label: {
              Text("Remove Icon")
            }
          }
        }
      }
      #if SKIP
        .withMediaPicker(
          type: MediaPickerType.library,
          isPresented: $store.iconPickerPresented,
          selectedImageURL: Binding(
            get: { store.selectedIconURL },
            set: { store.send(.iconSelected($0)) }
          )
        )
      #else
        .photosPicker(
          isPresented: $store.iconPickerPresented,
          selection: Binding(
            get: { nil },
            set: { item in
              if let item = item {
                Task {
                  if let data = try? await item.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                  {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                      UUID().uuidString + ".jpg")
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                      try? imageData.write(to: tempURL)
                      store.send(.iconSelected(tempURL))
                    }
                  }
                }
              }
            }
          ))
      #endif

      TextField("Username", text: $store.name)
        .textFieldStyle(.roundedBorder)
        .padding(.horizontal)

      Button {
        store.send(.saveButtonTapped)
      } label: {
        if store.isLoading {
          ProgressView()
        } else {
          Text("Save")
            .primaryButtonStyle()
        }
      }
      .disabled(store.name.isEmpty || store.isLoading)
    }
    .padding()
    .alert(
      "Error",
      isPresented: $store.isErrorAlertPresented,
      actions: {
        Button {
          store.send(.dismissError)
        } label: {
          Text("OK")
        }
      },
      message: {
        Text(store.error?.localizedDescription ?? "An unknown error occurred")
      }
    )
  }
}

#Preview {
  let previewMember = Member(
    id: "preview-id",
    name: nil,
    icon: nil,
    createdAt: Date(),
    updatedAt: Date()
  )

  return ProfileSetupView(store: ProfileSetupStore(member: previewMember))
}
