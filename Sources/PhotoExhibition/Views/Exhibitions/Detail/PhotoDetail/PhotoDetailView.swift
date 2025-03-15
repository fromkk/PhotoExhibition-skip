import Foundation
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
@MainActor
final class PhotoDetailStore: Store {
  enum Action {
    case closeButtonTapped
    case loadImage
    case editButtonTapped
    case updatePhoto(title: String, description: String)
    case deleteButtonTapped
    case confirmDeletePhoto
  }

  let exhibitionId: String
  let photo: Photo
  let isOrganizer: Bool

  var imageURL: URL? = nil
  var isLoading: Bool = false
  var showEditSheet: Bool = false
  var showDeleteConfirmation: Bool = false
  var error: Error? = nil
  var isDeleted: Bool = false

  private let imageCache: StorageImageCacheProtocol
  private let photoClient: PhotoClient

  init(
    exhibitionId: String,
    photo: Photo,
    isOrganizer: Bool,
    imageCache: StorageImageCacheProtocol = StorageImageCache.shared,
    photoClient: PhotoClient = DefaultPhotoClient()
  ) {
    self.exhibitionId = exhibitionId
    self.photo = photo
    self.isOrganizer = isOrganizer
    self.imageCache = imageCache
    self.photoClient = photoClient

    // 初期化時に画像の読み込みを開始
    Task {
      PhotoDetailStore.loadImage(self)
    }
  }

  func send(_ action: Action) {
    switch action {
    case .closeButtonTapped:
      // 閉じるアクションはViewで処理
      break
    case .loadImage:
      PhotoDetailStore.loadImage(self)
    case .editButtonTapped:
      if isOrganizer {
        showEditSheet = true
      }
    case .updatePhoto(let title, let description):
      PhotoDetailStore.updatePhoto(self, title: title, description: description)
    case .deleteButtonTapped:
      if isOrganizer {
        showDeleteConfirmation = true
      }
    case .confirmDeletePhoto:
      PhotoDetailStore.deletePhoto(self)
    }
  }

  private static func loadImage(_ store: PhotoDetailStore) {
    guard let path = store.photo.path else { return }

    store.isLoading = true

    Task {
      do {
        store.imageURL = try await store.imageCache.getImageURL(for: path)
      } catch {
        print("Failed to load image: \(error.localizedDescription)")
        store.error = error
      }

      store.isLoading = false
    }
  }

  private static func updatePhoto(_ store: PhotoDetailStore, title: String, description: String) {
    Task {
      do {
        try await store.photoClient.updatePhoto(
          exhibitionId: store.exhibitionId,
          photoId: store.photo.id,
          title: title.isEmpty ? nil : title,
          description: description.isEmpty ? nil : description
        )
      } catch {
        print("Failed to update photo: \(error.localizedDescription)")
        store.error = error
      }

      store.showEditSheet = false
    }
  }

  private static func deletePhoto(_ store: PhotoDetailStore) {
    Task {
      do {
        try await store.photoClient.deletePhoto(
          exhibitionId: store.exhibitionId, photoId: store.photo.id)
        store.isDeleted = true
      } catch {
        print("Failed to delete photo: \(error.localizedDescription)")
        store.error = error
      }

      store.showDeleteConfirmation = false
    }
  }
}

struct PhotoDetailView: View {
  @Bindable var store: PhotoDetailStore
  @Environment(\.dismiss) private var dismiss

  init(exhibitionId: String, photo: Photo, isOrganizer: Bool) {
    self.store = PhotoDetailStore(
      exhibitionId: exhibitionId,
      photo: photo,
      isOrganizer: isOrganizer
    )
  }

  var body: some View {
    ZStack {
      // 背景を黒にする
      Color.black.ignoresSafeArea()

      // 写真表示
      if let imageURL = store.imageURL {
        AsyncImage(url: imageURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          case .failure:
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          case .empty:
            if store.isLoading {
              ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
              Color.clear
            }
          @unknown default:
            Color.clear
          }
        }
      } else if store.isLoading {
        ProgressView()
      } else {
        // 画像がない場合のプレースホルダー
        Image(systemName: "photo")
          .font(.system(size: 50))
          .foregroundStyle(.white.opacity(0.5))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      // オーバーレイコントロール
      VStack {
        // 上部コントロール
        HStack {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .font(.title2)
              .foregroundStyle(.white)
              .padding(12)
              .background(Circle().fill(Color.black.opacity(0.5)))
          }

          Spacer()

          if store.isOrganizer {
            HStack(spacing: 16) {
              Button {
                store.send(.editButtonTapped)
              } label: {
                Image(systemName: "pencil")
                  .font(.title2)
                  .foregroundStyle(.white)
                  .padding(12)
                  .background(Circle().fill(Color.black.opacity(0.5)))
              }

              Button {
                store.send(.deleteButtonTapped)
              } label: {
                Image(systemName: "trash")
                  .font(.title2)
                  .foregroundStyle(.white)
                  .padding(12)
                  .background(Circle().fill(Color.black.opacity(0.5)))
              }
            }
          }
        }
        .padding()

        Spacer()

        // 下部のタイトルと説明
        if store.photo.title != nil || store.photo.description != nil {
          VStack(alignment: .leading, spacing: 8) {
            if let title = store.photo.title {
              Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            }

            if let description = store.photo.description {
              Text(description)
                .font(.body)
                .foregroundStyle(.white)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
          .background(
            Rectangle()
              .fill(Color.black.opacity(0.6))
              .ignoresSafeArea(edges: .bottom)
          )
        }
      }
    }
    #if !SKIP
      .navigationBarHidden(true)
      .statusBar(hidden: true)
    #endif
    .sheet(isPresented: $store.showEditSheet) {
      PhotoEditView(
        title: store.photo.title ?? "",
        description: store.photo.description ?? ""
      ) { title, description in
        store.send(.updatePhoto(title: title, description: description))
      }
    }
    .alert("Delete Photo", isPresented: $store.showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        store.send(.confirmDeletePhoto)
      }
    } message: {
      Text("Are you sure you want to delete this photo? This action cannot be undone.")
    }
    .onChange(of: store.isDeleted) { _, isDeleted in
      if isDeleted {
        dismiss()
      }
    }
    .onAppear {
      // 画面表示時に画像を読み込む
      store.send(.loadImage)
    }
  }
}

// 写真編集用のビュー
struct PhotoEditView: View {
  @State private var title: String
  @State private var description: String
  @Environment(\.dismiss) private var dismiss

  let onSave: (String, String) -> Void

  init(title: String, description: String, onSave: @escaping (String, String) -> Void) {
    self._title = State(initialValue: title)
    self._description = State(initialValue: description)
    self.onSave = onSave
  }

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Title")) {
          TextField("Title", text: $title)
        }

        Section(header: Text("Description")) {
          TextEditor(text: $description)
            .frame(minHeight: 100)
        }
      }
      .navigationTitle("Edit Photo")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave(title, description)
          }
        }
      }
    }
  }
}

#Preview {
  PhotoDetailView(
    exhibitionId: "preview",
    photo: Photo(
      id: "photo1",
      path: nil,
      title: "Sample Photo",
      description:
        "This is a sample photo description that shows how the detail view will look with text overlay.",
      takenDate: Date(),
      photographer: "John Doe",
      createdAt: Date(),
      updatedAt: Date()
    ),
    isOrganizer: true
  )
}
