import Foundation
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

// PhotoDetailStoreDelegate プロトコルを追加
@MainActor
protocol PhotoDetailStoreDelegate: AnyObject {
  func photoDetailStore(_ store: PhotoDetailStore, didUpdatePhoto photo: Photo)
  func photoDetailStore(_ store: PhotoDetailStore, didDeletePhoto photoId: String)
}

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
    case showNextPhoto
    case showPreviousPhoto
    case reportButtonTapped
    case toggleUIVisible
  }

  let exhibitionId: String
  let photo: Photo
  let isOrganizer: Bool

  // デリゲートを追加
  weak var delegate: (any PhotoDetailStoreDelegate)?

  var imageURL: URL? = nil
  var isLoading: Bool = false
  var showEditSheet: Bool = false
  var showDeleteConfirmation: Bool = false
  var error: Error? = nil
  var isDeleted: Bool = false
  var shouldResetZoom: Bool = false
  var isUIVisible: Bool = true

  // 複数写真の管理用
  var photos: [Photo] = []
  var currentPhotoIndex: Int = 0
  var isLoadingPhotos: Bool = false

  private let imageCache: any StorageImageCacheProtocol
  private let photoClient: any PhotoClient
  private let analyticsClient: any AnalyticsClient

  var showReport: Bool = false
  private(set) var reportStore: ReportStore?

  init(
    exhibitionId: String,
    photo: Photo,
    isOrganizer: Bool,
    photos: [Photo],
    delegate: (any PhotoDetailStoreDelegate)? = nil,
    imageCache: any StorageImageCacheProtocol = StorageImageCache.shared,
    photoClient: any PhotoClient = DefaultPhotoClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.exhibitionId = exhibitionId
    self.photo = photo
    self.isOrganizer = isOrganizer
    self.delegate = delegate
    self.imageCache = imageCache
    self.photoClient = photoClient
    self.analyticsClient = analyticsClient
    self.photos = photos
    self.currentPhotoIndex = photos.firstIndex(where: { $0.id == photo.id }) ?? 0

    // 初期化時に画像の読み込みを開始
    Task {
      try await loadImage()
      await analyticsClient.analyticsScreen(name: "PhotoDetailView")
      await analyticsClient.send(
        AnalyticsEvents.photoViewed,
        parameters: [
          "photo_id": photo.id,
          "exhibition_id": exhibitionId,
        ])
    }
  }

  func send(_ action: Action) {
    switch action {
    case .closeButtonTapped:
      // 閉じるアクションはViewで処理
      break
    case .loadImage:
      Task {
        try await loadImage()
      }
    case .editButtonTapped:
      if isOrganizer {
        showEditSheet = true
      }
    case .updatePhoto(let title, let description):
      Task {
        try await updatePhoto(title: title, description: description)
      }
    case .deleteButtonTapped:
      if isOrganizer {
        showDeleteConfirmation = true
      }
    case .confirmDeletePhoto:
      Task {
        try await deletePhoto()
      }
    case .resetZoom:
      shouldResetZoom = true
      // 次のフレームでリセットフラグをオフにする
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒待機
        shouldResetZoom = false
      }
    case .showNextPhoto:
      Task {
        await showNextPhoto()
      }
    case .showPreviousPhoto:
      Task {
        await showPreviousPhoto()
      }
    case .reportButtonTapped:
      reportStore = ReportStore(type: .photo, id: photo.id)
      showReport = true
    case .toggleUIVisible:
      isUIVisible = !isUIVisible
    }
  }

  private func loadImage() async throws {
    guard let path = photo.imagePath else { return }

    isLoading = true

    Task {
      do {
        imageURL = try await imageCache.getImageURL(for: path)
      } catch {
        print("Failed to load image: \(error.localizedDescription)")
        self.error = error
      }

      isLoading = false
    }
  }

  private func updatePhoto(title: String, description: String) async throws {
    Task {
      do {
        try await photoClient.updatePhoto(
          exhibitionId: exhibitionId,
          photoId: photo.id,
          title: title.isEmpty ? nil : title,
          description: description.isEmpty ? nil : description
        )

        // 更新された写真情報を作成
        let updatedPhoto = Photo(
          id: photo.id,
          path: photo.path,
          title: title.isEmpty ? nil : title,
          description: description.isEmpty ? nil : description,
          takenDate: photo.takenDate,
          photographer: photo.photographer,
          createdAt: photo.createdAt,
          updatedAt: Date()
        )

        // 複数写真がある場合は現在の写真も更新
        if !photos.isEmpty,
          let index = photos.firstIndex(where: { $0.id == photo.id })
        {
          photos[index] = updatedPhoto
        }

        // デリゲートに通知
        delegate?.photoDetailStore(self, didUpdatePhoto: updatedPhoto)
      } catch {
        print("Failed to update photo: \(error.localizedDescription)")
        self.error = error
      }

      showEditSheet = false
    }
  }

  private func deletePhoto() async throws {
    Task {
      do {
        try await photoClient.deletePhoto(
          exhibitionId: exhibitionId, photoId: photo.id)
        isDeleted = true

        // デリゲートに通知
        delegate?.photoDetailStore(self, didDeletePhoto: photo.id)
      } catch {
        print("Failed to delete photo: \(error.localizedDescription)")
        self.error = error
      }

      showDeleteConfirmation = false
    }
  }

  private func showNextPhoto() async {
    guard !photos.isEmpty else { return }

    let nextIndex = (currentPhotoIndex + 1) % photos.count
    currentPhotoIndex = nextIndex

    // 次の写真の画像を読み込む
    Task {
      if let path = photos[nextIndex].imagePath {
        isLoading = true
        do {
          imageURL = try await imageCache.getImageURL(for: path)
          // 写真閲覧イベントを送信
          await analyticsClient.send(
            AnalyticsEvents.photoViewed,
            parameters: [
              "photo_id": photos[nextIndex].id,
              "exhibition_id": exhibitionId,
            ])
        } catch {
          print("Failed to load next image: \(error.localizedDescription)")
          self.error = error
        }
        isLoading = false
      }
    }
  }

  private func showPreviousPhoto() async {
    guard !photos.isEmpty else { return }

    let previousIndex = (currentPhotoIndex - 1 + photos.count) % photos.count
    currentPhotoIndex = previousIndex

    // 前の写真の画像を読み込む
    Task {
      if let path = photos[previousIndex].imagePath {
        isLoading = true
        do {
          imageURL = try await imageCache.getImageURL(for: path)
          // 写真閲覧イベントを送信
          await analyticsClient.send(
            AnalyticsEvents.photoViewed,
            parameters: [
              "photo_id": photos[previousIndex].id,
              "exhibition_id": exhibitionId,
            ])
        } catch {
          print("Failed to load previous image: \(error.localizedDescription)")
          self.error = error
        }
        isLoading = false
      }
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

  // スワイプ検出用
  @State private var dragOffset: CGFloat = 0

  init(store: PhotoDetailStore) {
    self.store = store
  }

  var body: some View {
    NavigationStack {
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
                        // valueをDoubleに明示的に変換してからCGFloatに変換
                        let magnitudeDouble = Double(value.magnitude)
                        let magnitudeValue = CGFloat(magnitudeDouble)
                        let newScale = lastScale * magnitudeValue
                        // 1.0〜5.0の範囲に制限
                        scale = min(max(newScale, CGFloat(1.0)), CGFloat(5.0))
                      }
                      .onEnded { _ in
                        lastScale = scale
                        // スケールが1.0未満なら1.0に戻す
                        if scale < CGFloat(1.0) {
                          scale = CGFloat(1.0)
                          lastScale = CGFloat(1.0)
                        }
                        // スケールが5.0を超えたら5.0に制限
                        if scale > CGFloat(5.0) {
                          scale = CGFloat(5.0)
                          lastScale = CGFloat(5.0)
                        }
                        // スケールが1.0になったら位置もリセット
                        if scale <= CGFloat(1.0) {
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
                        if scale > CGFloat(1.0) {
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
                  // 水平方向のスワイプジェスチャー（拡大していない時のみ有効）
                  .simultaneousGesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                      .onChanged { value in
                        // 拡大していない時のみスワイプを有効にする
                        if scale <= CGFloat(1.0) {
                          dragOffset = value.translation.width
                        }
                      }
                      .onEnded { value in
                        // スワイプの方向と距離に基づいて写真を切り替え
                        if scale <= CGFloat(1.0) {
                          let threshold: CGFloat = 50
                          if dragOffset > threshold {
                            // 右にスワイプ -> 前の写真
                            store.send(.showPreviousPhoto)
                          } else if dragOffset < -threshold {
                            // 左にスワイプ -> 次の写真
                            store.send(.showNextPhoto)
                          }
                          dragOffset = 0
                        }
                      }
                  )
                  // ダブルタップでリセット
                  .onTapGesture(count: 2) {
                    resetZoom()
                  }
                #else
                  .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                      .onChanged { value in
                        // 拡大していない時のみスワイプを有効にする
                        if scale <= CGFloat(1.0) {
                          dragOffset = value.translation.width
                        }
                      }
                      .onEnded { value in
                        // スワイプの方向と距離に基づいて写真を切り替え
                        if scale <= CGFloat(1.0) {
                          let threshold: CGFloat = 50
                          if dragOffset > threshold {
                            // 右にスワイプ -> 前の写真
                            store.send(.showPreviousPhoto)
                          } else if dragOffset < -threshold {
                            // 左にスワイプ -> 次の写真
                            store.send(.showNextPhoto)
                          }
                          dragOffset = 0
                        }
                      }
                  )
                #endif
                .gesture(
                  DragGesture(minimumDistance: 20, coordinateSpace: .global)
                    .onChanged { value in
                      // 拡大していない時のみスワイプを有効にする
                      if scale <= CGFloat(1.0) {
                        // 下方向のスワイプを検出
                        if value.translation.height > 0
                          && abs(value.translation.width) < abs(value.translation.height)
                        {
                          offset = CGSize(width: 0, height: value.translation.height)
                        }
                      }
                    }
                    .onEnded { value in
                      // スワイプの方向と距離に基づいて画面を閉じる
                      if scale <= CGFloat(1.0) {
                        let threshold: CGFloat = 100
                        if value.translation.height > threshold
                          && abs(value.translation.width) < abs(value.translation.height)
                        {
                          dismiss()
                        } else {
                          // スワイプが閾値に達していない場合は元の位置に戻す
                          withAnimation(.spring()) {
                            offset = .zero
                          }
                        }
                      }
                    }
                )
                .onTapGesture {
                  withAnimation {
                    store.send(.toggleUIVisible)
                  }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure:
              Image(systemName: SystemImageMapping.getIconName(from: "exclamationmark.triangle"))
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
          Image(systemName: SystemImageMapping.getIconName(from: "photo"))
            .font(.system(size: 50))
            .foregroundStyle(.white.opacity(0.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        // オーバーレイコントロール
        if store.isUIVisible {
          VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
              if store.photos.count > 1 {
                Text("\(store.currentPhotoIndex + 1) / \(store.photos.count)")
                  .font(.subheadline)
                  .foregroundStyle(.white)
                  .padding(8)
                  .background(Color.black.opacity(0.5))
                  .clipShape(Capsule())
                  .padding(.bottom, 8)
              }

              // 下部のタイトルと説明
              if let title = store.photos.isEmpty
                ? store.photo.title : store.photos[store.currentPhotoIndex].title
              {
                Text(title)
                  .font(.subheadline)
                  .foregroundStyle(.white)
              }

              if let description = store.photos.isEmpty
                ? store.photo.description : store.photos[store.currentPhotoIndex].description
              {
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
      .toolbar(store.isUIVisible ? .visible : .hidden, for: .navigationBar)
      .toolbar(store.isUIVisible ? .visible : .hidden, for: .bottomBar)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: SystemImageMapping.getIconName(from: "xmark"))
              .foregroundStyle(.white)
              .accessibilityLabel("Close")
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          HStack(spacing: 16) {
            if scale > CGFloat(1.0) {
              Button {
                resetZoom()
              } label: {
                Image(systemName: SystemImageMapping.getIconName(from: "arrow.counterclockwise"))
                  .foregroundStyle(.white)
                  .accessibilityLabel("Reset zoom")
              }
            }

            if store.isOrganizer {
              Button {
                store.send(.editButtonTapped)
              } label: {
                Image(systemName: SystemImageMapping.getIconName(from: "pencil"))
                  .foregroundStyle(.white)
                  .accessibilityLabel("Edit photo")
              }

              Button {
                store.send(.deleteButtonTapped)
              } label: {
                Image(systemName: SystemImageMapping.getIconName(from: "trash"))
                  .foregroundStyle(.white)
                  .accessibilityLabel("Delete photo")
              }
            } else {
              Button {
                store.send(.reportButtonTapped)
              } label: {
                Image(systemName: SystemImageMapping.getIconName(from: "exclamationmark.triangle"))
                  .foregroundStyle(.white)
                  .accessibilityLabel("Report photo")
              }
            }
          }
        }

        ToolbarItem(placement: .bottomBar) {
          // 左右のナビゲーションボタン（拡大していない時のみ表示）
          if scale <= CGFloat(1.0) && store.photos.count > 1 {
            HStack {
              // 前の写真ボタン
              Button {
                store.send(.showPreviousPhoto)
              } label: {
                Image(systemName: SystemImageMapping.getIconName(from: "chevron.left"))
                  .foregroundStyle(.white)
                  .padding(16)
                  .accessibilityLabel("Previous photo")
              }
              .padding(.leading)

              Spacer()

              // 次の写真ボタン
              Button {
                store.send(.showNextPhoto)
              } label: {
                Image(systemName: SystemImageMapping.getIconName(from: "chevron.right"))
                  .foregroundStyle(.white)
                  .padding(16)
                  .accessibilityLabel("Next photo")
              }
              .padding(.trailing)
            }
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Color.black.opacity(0), for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarColorScheme(.dark)
    }
    #if !SKIP && os(iOS)
      .statusBar(hidden: true)
    #endif
    .sheet(isPresented: $store.showEditSheet) {
      let currentPhoto = store.photos.isEmpty ? store.photo : store.photos[store.currentPhotoIndex]
      PhotoEditView(
        title: currentPhoto.title ?? "",
        description: currentPhoto.description ?? ""
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
      if newScale <= CGFloat(1.0) && oldScale > CGFloat(1.0) {
        withAnimation(.spring()) {
          offset = .zero
          lastOffset = .zero
        }
      }
    }
    .onChange(of: store.currentPhotoIndex) { _, _ in
      // 写真が切り替わったらズームをリセット
      resetZoom()
    }
    .onAppear {
      // 画面表示時に画像を読み込む
      store.send(.loadImage)
    }
    .sheet(isPresented: $store.showReport) {
      if let reportStore = store.reportStore {
        ReportView(store: reportStore)
      }
    }
  }

  private func resetZoom() {
    withAnimation(.spring()) {
      scale = CGFloat(1.0)
      lastScale = CGFloat(1.0)
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
      .navigationTitle(Text("Edit Photo"))
      #if !SKIP && os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
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
    store: PhotoDetailStore(
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
      isOrganizer: true,
      photos: []
    )
  )
}
