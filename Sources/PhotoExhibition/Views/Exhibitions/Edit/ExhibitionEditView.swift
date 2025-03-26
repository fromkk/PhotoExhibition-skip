import OSLog
import SkipKit
import SwiftUI

#if canImport(Photos)
  import Photos
  import PhotosUI
#endif

#if canImport(Observation)
  import Observation
#endif
#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "ExhibitionsStore")

// 展示会の作成・編集用のStore
@Observable
final class ExhibitionEditStore: Store {
  enum Errors: Error {
    case noExhibitionId
  }

  enum Mode: Equatable {
    case create
    case edit(Exhibition)
  }

  enum Action {
    case task
    case saveButtonTapped
    case cancelButtonTapped
    case changeCoverImageButtonTapped
    case updateFrom(Date)
    case updateTo(Date)
    case updateCoverImage(URL?)
    case photoPicked(URL)
    case dismissError
  }

  var name: String = ""
  var description: String = ""
  var from: Date = Date()
  var to: Date = Date().addingTimeInterval(60 * 60 * 24 * 7)  // 1週間後

  var status: ExhibitionStatus = .draft

  var isLoading: Bool = false
  var error: (any Error)? = nil
  var showError: Bool = false
  var shouldDismiss: Bool = false

  var imagePickerPresented: Bool = false
  var pickedImageURL: URL? {
    didSet {
      if pickedImageURL != nil {
        coverImageURL = nil
      }
    }
  }
  var coverImageURL: URL?
  var isLoadingCoverImage: Bool = false
  var coverImagePath: String?

  private let mode: Mode
  weak var delegate: (any ExhibitionEditStoreDelegate)?
  private let currentUserClient: any CurrentUserClient
  private let exhibitionsClient: any ExhibitionsClient
  private let storageClient: any StorageClient
  private let imageCache: any StorageImageCacheProtocol
  private let analyticsClient: any AnalyticsClient

  init(
    mode: Mode,
    delegate: (any ExhibitionEditStoreDelegate)? = nil,
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    exhibitionsClient: any ExhibitionsClient = DefaultExhibitionsClient(),
    storageClient: any StorageClient = DefaultStorageClient(),
    imageCache: any StorageImageCacheProtocol = StorageImageCache.shared,
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.mode = mode
    self.delegate = delegate
    self.currentUserClient = currentUserClient
    self.exhibitionsClient = exhibitionsClient
    self.storageClient = storageClient
    self.imageCache = imageCache
    self.analyticsClient = analyticsClient

    if case .edit(let exhibition) = mode {
      self.name = exhibition.name
      self.description = exhibition.description ?? ""
      self.from = exhibition.from
      self.to = exhibition.to
      self.coverImagePath = exhibition.coverImagePath
      self.status = exhibition.status

      // カバー画像の読み込み
      if let coverImagePath = exhibition.coverPath {
        loadCoverImage(path: coverImagePath)
      }
    }
  }

  func send(_ action: Action) {
    logger.info("action \(String(describing: action))")
    switch action {
    case .task:
      Task {
        await analyticsClient.analyticsScreen(name: "ExhibitionEditView")
      }
    case .saveButtonTapped:
      guard !name.isEmpty else {
        error = ExhibitionEditError.emptyName
        showError = true
        return
      }

      guard let user = currentUserClient.currentUser() else {
        error = ExhibitionEditError.userNotLoggedIn
        showError = true
        return
      }

      isLoading = true
      Task {
        do {
          try await saveExhibition(user: user)
          shouldDismiss = true
        } catch {
          self.error = error
          showError = true
        }
        isLoading = false
      }
    case .cancelButtonTapped:
      cancel()
    case .updateFrom(let newFrom):
      from = newFrom
      if to < newFrom {
        to = newFrom.addingTimeInterval(60 * 60 * 24)  // 1日後
      }
    case .updateTo(let newTo):
      to = newTo
    case .updateCoverImage(let url):
      coverImageURL = url
    case .changeCoverImageButtonTapped:
      imagePickerPresented = true
    case .photoPicked(let url):
      pickedImageURL = url
    case .dismissError:
      error = nil
      showError = false
    }
  }

  private func saveExhibition(user: User) async throws {
    var exhibitionId: String?

    // 編集モードの場合は既存のIDを使用、作成モードの場合は新しいIDを生成
    switch mode {
    case .edit(let exhibition):
      exhibitionId = exhibition.id
    case .create:
      exhibitionId = UUID().uuidString
    }

    // 先にFirestoreにデータを作成/更新する（カバー画像パスなし）
    var initialData: [String: any Sendable] = [
      "name": name,
      "description": description,
      "from": Timestamp(date: from),
      "to": Timestamp(date: to),
      "organizer": user.uid,
      "updatedAt": FieldValue.serverTimestamp(),
      "status": status.rawValue,
    ]

    // 作成モードの場合はcreatedAtを設定
    if case .create = mode {
      initialData["createdAt"] = FieldValue.serverTimestamp()
    }

    // Firestoreにデータを作成/更新
    switch mode {
    case .create:
      if let exhibitionId = exhibitionId {
        try await exhibitionsClient.create(id: exhibitionId, data: initialData)
      } else {
        throw Errors.noExhibitionId
      }
    case .edit(let exhibition):
      try await exhibitionsClient.update(id: exhibition.id, data: initialData)
    }

    // カバー画像をアップロードする（新しい画像が選択されている場合のみ）
    if let pickedImageURL = pickedImageURL, let exhibitionId = exhibitionId {
      do {
        let fileName =
          "cover." + (pickedImageURL.pathExtension.isEmpty ? "jpg" : pickedImageURL.pathExtension)
        let storagePath = "exhibitions/\(exhibitionId)/\(fileName)"

        // 画像をアップロード
        try await storageClient.upload(from: pickedImageURL, to: storagePath)

        // カバー画像パスでFirestoreを更新
        let updateData: [String: any Sendable] = [
          "coverImagePath": storagePath,
          "updatedAt": FieldValue.serverTimestamp(),
          "status": status.rawValue,
        ]

        try await exhibitionsClient.update(id: exhibitionId, data: updateData)
      } catch {
        logger.error("Failed to upload cover image: \(error.localizedDescription)")
        // 画像アップロードに失敗しても、展示会自体は作成/更新されているので、エラーはスローしない
      }
    }

    // アナリティクスイベントを記録
    switch mode {
    case .create:
      await analyticsClient.send(.exhibitionCreated, parameters: [:])
    case .edit:
      await analyticsClient.send(.exhibitionEdited, parameters: [:])
    }

    // 保存が完了したらデリゲートに通知
    delegate?.didSaveExhibition()
  }

  private func cancel() {
    // デリゲートに通知
    delegate?.didCancelExhibition()
    shouldDismiss = true
  }

  private func loadCoverImage(path: String) {
    isLoadingCoverImage = true
    Task {
      do {
        // StorageImageCacheを使って画像をローカルにダウンロードして保存し、そのURLを取得
        let localURL = try await imageCache.getImageURL(for: path)
        self.coverImageURL = localURL
      } catch {
        logger.error("Failed to get download URL: \(error.localizedDescription)")
      }
      isLoadingCoverImage = false
    }
  }
}

enum ExhibitionEditError: Error, LocalizedError, Hashable {
  case emptyName
  case userNotLoggedIn
  case saveFailed(String)

  var errorDescription: String? {
    switch self {
    case .emptyName:
      return "Please enter exhibition name"
    case .userNotLoggedIn:
      return "Please login"
    case .saveFailed(let message):
      return "Failed to save: \(message)"
    }
  }
}

@MainActor
protocol ExhibitionEditStoreDelegate: AnyObject {
  func didSaveExhibition()
  func didCancelExhibition()
}

struct ExhibitionEditView: View {
  @Bindable var store: ExhibitionEditStore
  @Environment(\.dismiss) private var dismiss

  init(store: ExhibitionEditStore) {
    self.store = store
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Cover Image") {
          VStack(alignment: .leading, spacing: 16) {
            if store.coverImageURL != nil || store.pickedImageURL != nil {
              AsyncImage(
                url: store.coverImageURL ?? store.pickedImageURL,
                content: { image in
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                },
                placeholder: {
                  ProgressView()
                }
              )
            } else if store.coverImagePath != nil {
              // カバー画像の画像パスがある場合はローディングを表示
              ProgressView()
            }

            Button {
              store.send(.changeCoverImageButtonTapped)
            } label: {
              Text("Select Cover Image")
            }
            #if SKIP
              .withMediaPicker(
                type: MediaPickerType.library,
                isPresented: $store.imagePickerPresented,
                selectedImageURL: $store.pickedImageURL
              )
            #else
              .photosPicker(
                isPresented: $store.imagePickerPresented,
                selection: Binding(
                  get: { nil },
                  set: { item in
                    if let item = item {
                      Task {
                        do {
                          if let data = try await item.loadTransferable(type: Data.self) {
                            let ext: String
                            switch data.imageFormat {
                            case .gif:
                              ext = "gif"
                            case .jpeg:
                              ext = "jpg"
                            case .png:
                              ext = "png"
                            default:
                              // サポートされていない画像形式のエラーを表示
                              store.error = ImageFormatError.unknownImageFormat
                              store.showError = true
                              return
                            }
                            let tempURL = FileManager.default.temporaryDirectory
                              .appendingPathComponent(
                                UUID().uuidString + "." + ext)
                            try data.write(to: tempURL)
                            store.pickedImageURL = tempURL
                          }
                        } catch {
                          logger.error("error \(error.localizedDescription)")
                          store.error = error
                          store.showError = true
                        }
                      }
                    }
                  }
                ),
                matching: .images
              )
            #endif
          }
        }

        Section("Basic Information") {
          VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
              Text("Exhibition Name")
                .fontWeight(.semibold)
              TextField("Exhibition Name", text: $store.name)
                #if !SKIP
                  .padding(8)
                  .overlay {
                    RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 1))
                  }
                #endif
            }

            VStack(alignment: .leading, spacing: 8) {
              Text("Description")
                .fontWeight(.semibold)
              TextEditor(text: $store.description)
                .padding(8)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
                .overlay {
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 1))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
              Picker("Status", selection: $store.status) {
                ForEach(ExhibitionStatus.editableCases) { status in
                  Text(status.localizedKey).tag(status)
                }
              }
              .pickerStyle(.segmented)
              .disabled(store.status == .banned)
            }
          }
          .padding()
        }

        Section("Period") {
          DatePicker(
            "Start Date", selection: $store.from
          )
          .onChange(of: store.from) { _, newValue in
            store.send(.updateFrom(newValue))
          }
          .datePickerStyle(.compact)

          DatePicker(
            "End Date", selection: $store.to
          )
          .onChange(of: store.to) { _, newValue in
            store.send(.updateTo(newValue))
          }
          .datePickerStyle(.compact)
        }
      }
      .navigationTitle(store.name.isEmpty ? Text("New Exhibition") : Text(store.name))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            store.send(.cancelButtonTapped)
          }
          .disabled(store.isLoading)
        }

        ToolbarItem(placement: .primaryAction) {
          HStack {
            if store.isLoading {
              ProgressView()
            }
            Button("Save") {
              store.send(.saveButtonTapped)
            }
            .disabled(store.isLoading)
          }
        }
      }
      .alert("Error", isPresented: $store.showError) {
        Button("OK") {
          store.send(.dismissError)
        }
      } message: {
        if let errorMessage = store.error?.localizedDescription {
          Text(errorMessage)
        }
      }
      .onChange(of: store.shouldDismiss) { _, shouldDismiss in
        if shouldDismiss {
          dismiss()
        }
      }
      .task {
        store.send(.task)
      }
    }
  }
}

#Preview {
  ExhibitionEditView(store: ExhibitionEditStore(mode: .create))
}
