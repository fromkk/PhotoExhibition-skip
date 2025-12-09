import Foundation
import PhotoExhibitionModel
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

// PhotoDetailStoreDelegate プロトコルを追加
@MainActor
protocol PhotoDetailStoreDelegate: AnyObject {
  func photoDetailStore(_ store: PhotoDetailStore, didUpdatePhoto photo: Photo)
  func photoDetailStore(
    _ store: PhotoDetailStore,
    didDeletePhoto photoId: String
  )
}

enum SpatialPhotoMode {
  case `default`
  case overlay
}

@Observable
@MainActor
final class PhotoDetailStore: Store {
  enum Action {
    case task
    case closeButtonTapped
    case loadImage
    case editButtonTapped
    case updatePhoto(title: String, description: String, isThreeDimensional: Bool)
    case deleteButtonTapped
    case confirmDeletePhoto
    case resetZoom
    case showNextPhoto
    case showPreviousPhoto
    case reportButtonTapped
    case toggleUIVisible
    #if !SKIP
      case infoButtonTapped
    #endif
  }

  let exhibitionId: String
  var photo: Photo
  let isOrganizer: Bool

  // デリゲートを追加
  weak var delegate: (any PhotoDetailStoreDelegate)?

  var imageURL: URL? = nil {
    didSet {
      #if !SKIP
        if let imageURL {
          imageData = try? Data(contentsOf: imageURL)
        } else {
          imageData = nil
        }
      #endif
    }
  }
  var isLoading: Bool = false
  var showEditSheet: Bool = false
  var showDeleteConfirmation: Bool = false
  var error: Error? = nil
  var isDeleted: Bool = false
  var shouldResetZoom: Bool = false
  var isUIVisible: Bool = true

  var imageData: Data? {
    didSet {
      #if !SKIP
        let isSpatialPhoto = imageData?.isSpatialPhoto ?? false
        if isSpatialPhoto {
          if let (left, right) = imageData?.splitImages {
            self.leftImage = left
            self.rightImage = right
          } else {
            self.leftImage = nil
            self.rightImage = nil
          }
          spatialPhotoMotionManager.resume()
        } else {
          self.leftImage = nil
          self.rightImage = nil
        }
        self.isSpatialPhoto = isSpatialPhoto
        self.orientation =
          switch imageData?.orientation {
          case .up:
            .up
          case .left:
            .left
          case .leftMirrored:
            .leftMirrored
          case .right:
            .right
          case .rightMirrored:
            .rightMirrored
          case .down:
            .down
          case .downMirrored:
            .downMirrored
          case .upMirrored:
            .upMirrored
          case .none:
            .up
          }

      #endif
    }
  }
  #if !SKIP
    var orientation: Image.Orientation = .up
    var spatialPhotoMode: SpatialPhotoMode = .default
    var isSpatialPhoto: Bool = false
    var leftImage: CGImage?
    var rightImage: CGImage?
    var spatialPhotoMotionManager: SpatialPhotoMotionManager = .init()
    var adjustedValue: CGFloat {
      // value = -0.3 ~ 0.3 の範囲で、初期値を0にマッピング
      let normalizedValue = min(max(spatialPhotoMotionManager.deviceTilt / (.pi / 6), -1), 1)
      return normalizedValue * 0.05
    }
  #endif

  // 複数写真の管理用
  var photos: [Photo] = []
  var currentPhotoIndex: Int = 0
  var isLoadingPhotos: Bool = false
  var isForwarding: Bool?

  let imageCache: any StorageImageCacheProtocol
  private let photoClient: any PhotoClient
  private let analyticsClient: any AnalyticsClient

  var reportStore: ReportStore?

  #if !SKIP
    var exifStore: ExifStore?
  #endif

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
    self.currentPhotoIndex =
      photos.firstIndex(where: { $0.id == photo.id }) ?? 0
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      // 初期化時に画像の読み込みを開始
      Task {
        try await loadImage()
        await analyticsClient.analyticsScreen(name: "PhotoDetailView")
        await analyticsClient.send(
          AnalyticsEvents.photoViewed,
          parameters: [
            "photo_id": photo.id,
            "exhibition_id": exhibitionId,
          ]
        )
      }
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
    case .updatePhoto(let title, let description, let isThreeDimensional):
      Task {
        try await updatePhoto(title: title, description: description, isThreeDimensional: isThreeDimensional)
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
      isForwarding = true
      Task {
        await showNextPhoto()
      }
    case .showPreviousPhoto:
      isForwarding = false
      Task {
        await showPreviousPhoto()
      }
    case .reportButtonTapped:
      reportStore = ReportStore(type: .photo, id: photo.id)
    case .toggleUIVisible:
      isUIVisible = !isUIVisible
    #if !SKIP
      case .infoButtonTapped:
        exifStore = ExifStore(photo: photo)
    #endif
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

  private func updatePhoto(title: String, description: String, isThreeDimensional: Bool) async throws {
    Task {
      do {
        try await photoClient.updatePhoto(
          exhibitionId: exhibitionId,
          photoId: photo.id,
          title: title.isEmpty ? nil : title,
          description: description.isEmpty ? nil : description,
          isThreeDimensional: isThreeDimensional
        )

        // 更新された写真情報を作成
        let updatedPhoto = Photo(
          id: photo.id,
          path: photo.path,
          title: title.isEmpty ? nil : title,
          description: description.isEmpty ? nil : description,
          metadata: photo.metadata,
          isThreeDimensional: isThreeDimensional,
          sort: photo.sort,
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
          exhibitionId: exhibitionId,
          photoId: photo.id
        )
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
    photo = photos[nextIndex]
    imageURL = nil

    // 次の写真の画像を読み込む
    isLoading = true
    Task {
      if let path = photos[nextIndex].imagePath {
        do {
          imageURL = try await imageCache.getImageURL(for: path)
          // 写真閲覧イベントを送信
          await analyticsClient.send(
            AnalyticsEvents.photoViewed,
            parameters: [
              "photo_id": photos[nextIndex].id,
              "exhibition_id": exhibitionId,
            ]
          )
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
    photo = photos[previousIndex]
    imageURL = nil
    isLoading = true

    // 前の写真の画像を読み込む
    Task {
      if let path = photos[previousIndex].imagePath {
        do {
          imageURL = try await imageCache.getImageURL(for: path)
          // 写真閲覧イベントを送信
          await analyticsClient.send(
            AnalyticsEvents.photoViewed,
            parameters: [
              "photo_id": photos[previousIndex].id,
              "exhibition_id": exhibitionId,
            ]
          )
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
  @FocusState private var isFocused: Bool

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
        #if !SKIP
          let currentPhoto = store.photos.isEmpty ? store.photo : store.photos[store.currentPhotoIndex]
          if currentPhoto.isThreeDimensional {
            if #available(iOS 18.0, *) {
              PanoramaPhotoView(
                photo: currentPhoto,
                imageCache: store.imageCache,
                onClose: {
                  dismiss()
                }
              )
            } else if store.imageURL != nil {
              asyncImage
            } else {
              Color.clear
            }
          } else if store.imageURL != nil {
            if store.isSpatialPhoto, store.spatialPhotoMode == .overlay,
              let leftImage = store.leftImage, let rightImage = store.rightImage
            {
              ZStack {
                GeometryReader { proxy in
                  Image(
                    decorative: leftImage,
                    scale: 1,
                    orientation: store.orientation
                  )
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .offset(x: -proxy.size.width * store.adjustedValue)

                  Image(
                    decorative: rightImage,
                    scale: 1,
                    orientation: store.orientation
                  )
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .opacity(0.5)
                  .offset(x: proxy.size.width * store.adjustedValue)
                  .blendMode(.normal)
                }
                .compositingGroup()
              }
              .aspectRatio(1, contentMode: .fit)
              .modifier(
                SpatialPhotoGesturesModifier(
                  scale: $scale,
                  offset: $offset,
                  dragOffset: $dragOffset,
                  onPreviousPhoto: { store.send(.showPreviousPhoto) },
                  onNextPhoto: { store.send(.showNextPhoto) },
                  onDismiss: { dismiss() }
                ))
            } else {
              asyncImage
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
        #else
          if store.imageURL != nil {
            asyncImage
          } else if store.isLoading {
            ProgressView()
          } else {
            // 画像がない場合のプレースホルダー
            Image("photo", bundle: .module)
              .foregroundStyle(.white.opacity(0.5))
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
        #endif

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
                ? store.photo.title
                : store.photos[store.currentPhotoIndex].title
              {
                Text(title)
                  .font(.subheadline)
                  .foregroundStyle(.white)
              }

              if let description = store.photos.isEmpty
                ? store.photo.description
                : store.photos[store.currentPhotoIndex].description
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
          #if !SKIP
            .keyboardShortcut("w", modifiers: [.command])
          #endif
        }

        ToolbarItem(placement: .primaryAction) {
          HStack(spacing: 16) {
            #if !SKIP
              if store.photo.metadata != nil {
                Button {
                  store.send(.infoButtonTapped)
                } label: {
                  Image(systemName: "info.circle")
                }
                .accessibilityLabel(Text("Information"))
                .keyboardShortcut("i", modifiers: [.command])
              }
            #endif

            #if !SKIP
              if store.isSpatialPhoto {
                switch store.spatialPhotoMode {
                case .default:
                  Button {
                    store.spatialPhotoMode = .overlay
                  } label: {
                    Image(systemName: "sparkles")
                  }
                  .accessibilityLabel("Switch to spatial photo mode")
                case .overlay:
                  Button {
                    store.spatialPhotoMode = .default
                  } label: {
                    Image(systemName: "photo")
                  }
                  .accessibilityLabel("Switch to default photo mode")
                }
              }
            #endif

            if scale > CGFloat(1.0) {
              Button {
                resetZoom()
              } label: {
                Image(
                  systemName: SystemImageMapping.getIconName(
                    from: "arrow.counterclockwise"
                  )
                )
                .foregroundStyle(.white)
                .accessibilityLabel("Reset zoom")
              }
              #if !SKIP
                .keyboardShortcut("0", modifiers: [.command])
              #endif
            }

            if store.isOrganizer {
              Button {
                store.send(.editButtonTapped)
              } label: {
                Image(
                  systemName: SystemImageMapping.getIconName(from: "pencil")
                )
                .foregroundStyle(.white)
                .accessibilityLabel("Edit photo")
              }
              #if !SKIP
                .keyboardShortcut("e", modifiers: [.command])
              #endif

              Button {
                store.send(.deleteButtonTapped)
              } label: {
                Image(systemName: SystemImageMapping.getIconName(from: "trash"))
                  .foregroundStyle(.white)
                  .accessibilityLabel("Delete photo")
              }
              #if !SKIP
                .keyboardShortcut("d", modifiers: [.command])
              #endif
            } else {
              Button {
                store.send(.reportButtonTapped)
              } label: {
                Image(
                  systemName: SystemImageMapping.getIconName(
                    from: "exclamationmark.triangle"
                  )
                )
                .foregroundStyle(.white)
                .accessibilityLabel("Report photo")
              }
              #if !SKIP
                .keyboardShortcut("r", modifiers: [.command])
              #endif
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
                Image(
                  systemName: SystemImageMapping.getIconName(
                    from: "chevron.left"
                  )
                )
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
                Image(
                  systemName: SystemImageMapping.getIconName(
                    from: "chevron.right"
                  )
                )
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
      #if !SKIP
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled(true)
        .onKeyPress(.leftArrow) {
          guard !store.photos.isEmpty else {
            return .ignored
          }
          store.send(.showPreviousPhoto)
          return .handled
        }
        .onKeyPress(.rightArrow) {
          guard !store.photos.isEmpty else {
            return .ignored
          }
          store.send(.showNextPhoto)
          return .handled
        }
        .onAppear {
          isFocused = true
        }
        .onDisappear {
          isFocused = false
        }
      #endif
    }
    #if !SKIP && os(iOS)
      .statusBar(hidden: true)
    #endif
    .sheet(isPresented: $store.showEditSheet) {
      let currentPhoto =
        store.photos.isEmpty
        ? store.photo : store.photos[store.currentPhotoIndex]
      PhotoEditView(
        title: currentPhoto.title ?? "",
        description: currentPhoto.description ?? "",
        isThreeDimensional: currentPhoto.isThreeDimensional
      ) { title, description, isThreeDimensional in
        store.send(.updatePhoto(title: title, description: description, isThreeDimensional: isThreeDimensional))
      }
    }
    #if !SKIP
      .sheet(
        isPresented: Binding(
          get: {
            store.exifStore != nil
          },
          set: {
            if !$0 {
              store.exifStore = nil
            }
          }
        ),
        content: {
          if let store = store.exifStore {
            ExifView(store: store)
          }
        }
      )
    #endif
    .alert("Delete Photo", isPresented: $store.showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        store.send(.confirmDeletePhoto)
      }
    } message: {
      Text(
        "Are you sure you want to delete this photo? This action cannot be undone."
      )
    }
    .alert(
      "Error",
      isPresented: Binding(
        get: { store.error != nil },
        set: { if !$0 { store.error = nil } }
      ),
      actions: {
        Button {
        } label: {
          Text("OK")
        }
      },
      message: {
        if let message = store.error?.localizedDescription {
          Text(message)
        }
      }
    )
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
    .task {
      store.send(.task)
    }
    .sheet(
      isPresented: Binding(
        get: {
          store.reportStore != nil
        },
        set: {
          if !$0 {
            store.reportStore = nil
          }
        }
      )
    ) {
      if let reportStore = store.reportStore {
        ReportView(store: reportStore)
      }
    }
  }

  var asyncImage: some View {
    CrossPlatformAsyncImage(
      url: store.imageURL, animation: store.isForwarding != nil ? .default : nil
    ) { phase in
      switch phase {
      case .success(let image):
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaleEffect(scale)
          .offset(offset)
          .modifier(
            ImageGesturesModifier(
              scale: $scale,
              lastScale: $lastScale,
              offset: $offset,
              lastOffset: $lastOffset,
              dragOffset: $dragOffset,
              onPreviousPhoto: { store.send(.showPreviousPhoto) },
              onNextPhoto: { store.send(.showNextPhoto) },
              onDismiss: { dismiss() },
              onResetZoom: { resetZoom() }
            )
          )
          .onTapGesture {
            withAnimation {
              store.send(.toggleUIVisible)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .transition(.push(from: (store.isForwarding ?? true) ? .trailing : .leading))
          .id(store.currentPhotoIndex)
      case .failure:
        Image(
          systemName: SystemImageMapping.getIconName(
            from: "exclamationmark.triangle"
          )
        )
        .font(.largeTitle)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      case .empty:
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      @unknown default:
        Color.clear
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
  @State private var isThreeDimensional: Bool
  @Environment(\.dismiss) private var dismiss

  let onSave: (String, String, Bool) -> Void

  init(
    title: String,
    description: String,
    isThreeDimensional: Bool,
    onSave: @escaping (String, String, Bool) -> Void
  ) {
    self._title = State(initialValue: title)
    self._description = State(initialValue: description)
    self._isThreeDimensional = State(initialValue: isThreeDimensional)
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

        Section(header: Text("360 Degrees Photo")) {
          Toggle("360 Degrees Photo", isOn: $isThreeDimensional)
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
            onSave(title, description, isThreeDimensional)
          }
        }
      }
    }
  }
}

// MARK: - Gesture Modifiers

struct ImageGesturesModifier: ViewModifier {
  @Binding var scale: CGFloat
  @Binding var lastScale: CGFloat
  @Binding var offset: CGSize
  @Binding var lastOffset: CGSize
  @Binding var dragOffset: CGFloat

  let onPreviousPhoto: () -> Void
  let onNextPhoto: () -> Void
  let onDismiss: () -> Void
  let onResetZoom: () -> Void

  func body(content: Content) -> some View {
    content
      #if !SKIP
        .gesture(
          MagnificationGesture()
            .onChanged { value in
              let magnitudeDouble = Double(value.magnitude)
              let magnitudeValue = CGFloat(magnitudeDouble)
              let newScale = lastScale * magnitudeValue
              scale = min(max(newScale, CGFloat(1.0)), CGFloat(5.0))
            }
            .onEnded { _ in
              lastScale = scale
              if scale < CGFloat(1.0) {
                scale = CGFloat(1.0)
                lastScale = CGFloat(1.0)
              }
              if scale > CGFloat(5.0) {
                scale = CGFloat(5.0)
                lastScale = CGFloat(5.0)
              }
              if scale <= CGFloat(1.0) {
                withAnimation(.spring()) {
                  offset = .zero
                  lastOffset = .zero
                }
              }
            }
        )
        .simultaneousGesture(
          DragGesture()
            .onChanged { value in
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
        .simultaneousGesture(horizontalSwipeGesture)
        .simultaneousGesture(verticalSwipeGesture)
        .onTapGesture(count: 2) {
          onResetZoom()
        }
      #else
        .gesture(horizontalSwipeGesture)
        .gesture(verticalSwipeGesture)
      #endif
  }

  private var horizontalSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 20, coordinateSpace: .local)
      .onChanged { value in
        if scale <= CGFloat(1.0) {
          dragOffset = value.translation.width
        }
      }
      .onEnded { value in
        if scale <= CGFloat(1.0) {
          let threshold: CGFloat = 50
          if dragOffset > threshold {
            onPreviousPhoto()
          } else if dragOffset < -threshold {
            onNextPhoto()
          }
          dragOffset = 0
        }
      }
  }

  private var verticalSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 20, coordinateSpace: .global)
      .onChanged { value in
        if scale <= CGFloat(1.0) {
          if value.translation.height > 0
            && abs(value.translation.width) < abs(value.translation.height)
          {
            offset = CGSize(width: 0, height: value.translation.height)
          }
        }
      }
      .onEnded { value in
        if scale <= CGFloat(1.0) {
          let threshold: CGFloat = 100
          if value.translation.height > threshold
            && abs(value.translation.width) < abs(value.translation.height)
          {
            onDismiss()
          } else {
            withAnimation(.spring()) {
              offset = .zero
            }
          }
        }
      }
  }
}

struct SpatialPhotoGesturesModifier: ViewModifier {
  @Binding var scale: CGFloat
  @Binding var offset: CGSize
  @Binding var dragOffset: CGFloat

  let onPreviousPhoto: () -> Void
  let onNextPhoto: () -> Void
  let onDismiss: () -> Void

  func body(content: Content) -> some View {
    content
      #if !SKIP
        .simultaneousGesture(horizontalSwipeGesture)
        .simultaneousGesture(verticalSwipeGesture)
      #else
        .gesture(horizontalSwipeGesture)
        .gesture(verticalSwipeGesture)
      #endif
  }

  private var horizontalSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 20, coordinateSpace: .local)
      .onChanged { value in
        if scale <= CGFloat(1.0) {
          dragOffset = value.translation.width
        }
      }
      .onEnded { value in
        if scale <= CGFloat(1.0) {
          let threshold: CGFloat = 50
          if dragOffset > threshold {
            onPreviousPhoto()
          } else if dragOffset < -threshold {
            onNextPhoto()
          }
          dragOffset = 0
        }
      }
  }

  private var verticalSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 20, coordinateSpace: .global)
      .onChanged { value in
        if scale <= CGFloat(1.0) {
          if value.translation.height > 0
            && abs(value.translation.width) < abs(value.translation.height)
          {
            offset = CGSize(width: 0, height: value.translation.height)
          }
        }
      }
      .onEnded { value in
        if scale <= CGFloat(1.0) {
          let threshold: CGFloat = 100
          if value.translation.height > threshold
            && abs(value.translation.width) < abs(value.translation.height)
          {
            onDismiss()
          } else {
            withAnimation(.spring()) {
              offset = .zero
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
        path_256x256: nil,
        path_512x512: nil,
        path_1024x1024: nil,
        title: "Sample Photo",
        description:
          "This is a sample photo description that shows how the detail view will look with text overlay.",
        metadata: nil,
        isThreeDimensional: false,
        sort: 0,
        createdAt: Date(),
        updatedAt: Date()
      ),
      isOrganizer: true,
      photos: []
    )
  )
}
