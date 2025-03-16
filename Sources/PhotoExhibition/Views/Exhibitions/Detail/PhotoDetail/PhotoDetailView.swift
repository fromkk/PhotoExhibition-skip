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
    case resetZoom
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
  var shouldResetZoom: Bool = false

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
    case .resetZoom:
      shouldResetZoom = true
      // 次のフレームでリセットフラグをオフにする
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒待機
        shouldResetZoom = false
      }
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

  // ズームとパン用の状態変数
  @State private var scale: CGFloat = 1.0
  @State private var lastScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero

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
              .scaleEffect(scale)
              .offset(offset)
              #if !SKIP
                .gesture(
                  // ピンチジェスチャーで拡大縮小
                  MagnificationGesture()
                    .onChanged { value in
                      let newScale = lastScale * value
                      // 1.0〜5.0の範囲に制限
                      scale = min(max(newScale, 1.0), 5.0)
                    }
                    .onEnded { _ in
                      lastScale = scale
                      // スケールが1.0未満なら1.0に戻す
                      if scale < 1.0 {
                        scale = 1.0
                        lastScale = 1.0
                      }
                      // スケールが5.0を超えたら5.0に制限
                      if scale > 5.0 {
                        scale = 5.0
                        lastScale = 5.0
                      }
                      // スケールが1.0になったら位置もリセット
                      if scale <= 1.0 {
                        withAnimation(.spring()) {
                          offset = .zero
                          lastOffset = .zero
                        }
                      }
                    }
                )
                .simultaneousGesture(
                  // ドラッグジェスチャーでスクロール（拡大時のみ有効）
                  DragGesture()
                    .onChanged { value in
                      // 拡大時のみスクロールを有効にする
                      if scale > 1.0 {
                        offset = CGSize(
                          width: lastOffset.width + value.translation.width,
                          height: lastOffset.height + value.translation.height
                        )
                      }
                    }
                    .onEnded { _ in
                      lastOffset = offset
                    }
                )
                // ダブルタップでリセット
                .onTapGesture(count: 2) {
                  resetZoom()
                }
              #endif
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

          // リセットボタンを追加（拡大時のみ表示）
          if scale > 1.0 {
            Button {
              resetZoom()
            } label: {
              Image(systemName: "arrow.counterclockwise")
                .font(.title2)
                .foregroundStyle(.white)
                .padding(12)
                .background(Circle().fill(Color.black.opacity(0.5)))
            }
          }

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
    .onChange(of: store.shouldResetZoom) { _, shouldReset in
      if shouldReset {
        resetZoom()
      }
    }
    .onChange(of: scale) { oldScale, newScale in
      // スケールが1.0になったら位置をリセット
      if newScale <= 1.0 && oldScale > 1.0 {
        withAnimation(.spring()) {
          offset = .zero
          lastOffset = .zero
        }
      }
    }
    .onAppear {
      // 画面表示時に画像を読み込む
      store.send(.loadImage)
    }
  }

  private func resetZoom() {
    withAnimation(.spring()) {
      scale = 1.0
      lastScale = 1.0
      offset = .zero
      lastOffset = .zero
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
