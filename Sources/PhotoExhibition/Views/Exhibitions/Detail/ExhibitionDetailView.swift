import Foundation
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

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ExhibitionDetai")

// 展示会の写真の最大枚数
private let maxExhibitionPhotos = 30

@Observable
final class ExhibitionDetailStore: Store, PhotoDetailStoreDelegate,
  ExhibitionEditStoreDelegate, FootprintsListStoreDelegate
{
  enum Action {
    case checkPermissions
    case editExhibition
    case deleteExhibition
    case confirmDelete
    case cancelDelete
    case loadCoverImage
    case addPhotoButtonTapped
    case photoSelected(URL?)
    case loadPhotos
    case photoTapped(Photo)
    case updateUploadedPhoto(title: String, description: String)
    case cancelPhotoEdit
    case reloadExhibition
    case reportButtonTapped
    case moveCompleted
    case showOrganizerProfile
    case dismissError
    case recordFootprint
    case loadFootprints
    case loadMoreFootprints
    case toggleFootprint
    case showFootprintsListTapped
  }

  var exhibition: Exhibition
  var showEditSheet: Bool = false
  var showDeleteConfirmation: Bool = false
  var isDeleting: Bool = false
  var error: Error? = nil
  var shouldDismiss: Bool = false
  var isOrganizer: Bool = false
  var coverImageURL: URL? = nil
  var isLoadingCoverImage: Bool = false
  var isErrorAlertPresented: Bool = false

  // 写真関連
  var photos: [Photo] = []
  var isLoadingPhotos: Bool = false
  var photoPickerPresented: Bool = false
  var selectedPhotoURL: URL? = nil
  var isUploadingPhoto: Bool = false
  var photoToDelete: String? = nil
  var selectedPhoto: Photo? = nil
  var showPhotoDetail: Bool = false
  var uploadedPhoto: Photo? = nil
  var showPhotoEditSheet: Bool = false

  // 足跡関連
  var isLoadingFootprints: Bool = false
  var hasAddedFootprint: Bool = false
  var visitorCount: Int = 0
  var isTogglingFootprint: Bool = false

  // PhotoDetailStoreを保持
  private(set) var photoDetailStore: PhotoDetailStore?

  // 主催者プロフィール
  private(set) var organizerProfileStore: OrganizerProfileStore?
  var isOrganizerProfileShown: Bool = false

  var showReport: Bool = false
  private(set) var reportStore: ReportStore?

  private let exhibitionsClient: any ExhibitionsClient
  private let currentUserClient: any CurrentUserClient
  private let storageClient: any StorageClient
  let imageCache: any StorageImageCacheProtocol
  let photoClient: any PhotoClient
  private let analyticsClient: any AnalyticsClient
  private let footprintClient: any FootprintClient

  var exhibitionEditStore: ExhibitionEditStore?

  // 足跡一覧画面
  private(set) var footprintsListStore: FootprintsListStore?
  var isShowFootprintsList: Bool = false

  init(
    exhibition: Exhibition,
    exhibitionsClient: any ExhibitionsClient = DefaultExhibitionsClient(),
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    storageClient: any StorageClient = DefaultStorageClient(),
    imageCache: any StorageImageCacheProtocol = StorageImageCache.shared,
    photoClient: any PhotoClient = DefaultPhotoClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient(),
    footprintClient: any FootprintClient = DefaultFootprintClient()
  ) {
    self.exhibition = exhibition
    self.exhibitionsClient = exhibitionsClient
    self.currentUserClient = currentUserClient
    self.storageClient = storageClient
    self.imageCache = imageCache
    self.photoClient = photoClient
    self.analyticsClient = analyticsClient
    self.footprintClient = footprintClient

    // Check if current user is the organizer
    if let currentUser = currentUserClient.currentUser() {
      self.isOrganizer = currentUser.uid == exhibition.organizer.id

      // 足跡の状態を確認
      checkFootprintStatus()
    }
  }

  func send(_ action: Action) {
    switch action {
    case .checkPermissions:
      checkIfUserIsOrganizer()
      Task {
        await analyticsClient.analyticsScreen(name: "ExhibitionDetailView")
        await analyticsClient.send(
          AnalyticsEvents.exhibitionViewed, parameters: ["exhibition_id": exhibition.id])
      }
    case .editExhibition:
      if isOrganizer {
        exhibitionEditStore = ExhibitionEditStore(
          mode: .edit(exhibition),
          delegate: self,
          currentUserClient: currentUserClient,
          exhibitionsClient: exhibitionsClient,
          storageClient: storageClient,
          imageCache: imageCache
        )
        showEditSheet = true
      }
    case .deleteExhibition:
      if isOrganizer {
        showDeleteConfirmation = true
      }
    case .confirmDelete:
      deleteExhibition()
    case .cancelDelete:
      showDeleteConfirmation = false
    case .loadCoverImage:
      loadCoverImage()
    case .addPhotoButtonTapped:
      if isOrganizer && photos.count < maxExhibitionPhotos {
        photoPickerPresented = true
      }
    case .photoSelected(let url):
      if let url = url {
        uploadPhoto(from: url)
      }
    case .loadPhotos:
      loadPhotos()
    case .photoTapped(let photo):
      selectedPhoto = photo
      // PhotoDetailStoreを生成
      photoDetailStore = PhotoDetailStore(
        exhibitionId: exhibition.id,
        photo: photo,
        isOrganizer: isOrganizer,
        photos: photos,
        delegate: self,
        imageCache: imageCache,
        photoClient: photoClient
      )
      showPhotoDetail = true
    case .updateUploadedPhoto(let title, let description):
      updateUploadedPhoto(title: title, description: description)
    case .cancelPhotoEdit:
      uploadedPhoto = nil
      showPhotoEditSheet = false
    case .reloadExhibition:
      reloadExhibition()
    case .reportButtonTapped:
      reportStore = ReportStore(type: .exhibition, id: exhibition.id)
      showReport = true
    case .moveCompleted:
      movePhoto()
    case .showOrganizerProfile:
      showOrganizerProfile()
    case .dismissError:
      error = nil
      isErrorAlertPresented = false
    case .recordFootprint:
      recordFootprint()
    case .loadFootprints:
      loadFootprints()
    case .loadMoreFootprints:
      loadMoreFootprints()
    case .toggleFootprint:
      toggleFootprint()
    case .showFootprintsListTapped:
      showFootprintsList()
    }
  }

  private func checkIfUserIsOrganizer() {
    if let currentUser = currentUserClient.currentUser() {
      isOrganizer = currentUser.uid == exhibition.organizer.id

      // 足跡の状態を確認
      checkFootprintStatus()
    } else {
      isOrganizer = false
    }
  }

  private func checkFootprintStatus() {
    Task {
      do {
        // 訪問者数を取得
        visitorCount = try await footprintClient.getVisitorCount(exhibitionId: exhibition.id)

        // 現在のユーザーが足跡を残しているか確認
        if let currentUser = currentUserClient.currentUser() {
          hasAddedFootprint = try await footprintClient.hasAddedFootprint(
            exhibitionId: exhibition.id,
            userId: currentUser.uid
          )
        }
      } catch {
        logger.error("Failed to check footprint status: \(error.localizedDescription)")
      }
    }
  }

  private func loadCoverImage() {
    guard let coverImagePath = exhibition.coverPath else { return }

    isLoadingCoverImage = true

    Task {
      do {
        let localURL = try await imageCache.getImageURL(for: coverImagePath)
        self.coverImageURL = localURL
      } catch {
        print("Failed to load cover image: \(error.localizedDescription)")
      }

      isLoadingCoverImage = false
    }
  }

  private func loadPhotos() {
    isLoadingPhotos = true

    Task {
      do {
        self.photos = try await photoClient.fetchPhotos(
          exhibitionId: exhibition.id)
      } catch {
        print("Failed to load photos: \(error.localizedDescription)")
        self.error = error
      }

      isLoadingPhotos = false
    }
  }

  private func uploadPhoto(from url: URL) {
    guard isOrganizer else { return }

    isUploadingPhoto = true

    Task {
      do {
        // 一意のIDを生成
        let photoId = UUID().uuidString
        let photoPath = "exhibitions/\(exhibition.id)/photos/\(photoId)"

        // 先に写真情報をFirestoreに保存（パスのみ）
        let initialPhoto = try await photoClient.addPhoto(
          exhibitionId: exhibition.id,
          photoId: photoId,
          path: photoPath,
          sort: photos.count
        )

        // 写真をStorageにアップロード
        do {
          try await storageClient.upload(from: url, to: photoPath)

          // 新しい写真を追加
          photos.append(initialPhoto)

          // アナリティクスイベントを記録
          await analyticsClient.send(.photoUploaded, parameters: [:])

          // アップロードした写真を選択して編集シートを表示
          uploadedPhoto = initialPhoto
          showPhotoEditSheet = true
        } catch {
          // 画像アップロードに失敗した場合、Firestoreから写真データを削除
          print("Failed to upload photo: \(error.localizedDescription)")
          try? await photoClient.deletePhoto(
            exhibitionId: exhibition.id, photoId: initialPhoto.id)
          self.error = error
        }
      } catch {
        print("Failed to create photo data: \(error.localizedDescription)")
        self.error = error
      }

      isUploadingPhoto = false
    }
  }

  private func updateUploadedPhoto(title: String, description: String) {
    guard let photo = uploadedPhoto else { return }

    Task {
      do {
        try await photoClient.updatePhoto(
          exhibitionId: exhibition.id,
          photoId: photo.id,
          title: title.isEmpty ? nil : title,
          description: description.isEmpty ? nil : description
        )

        // 写真リストを更新
        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
          // 新しいPhotoインスタンスを作成（titleとdescriptionを更新）
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
          photos[index] = updatedPhoto
        }
      } catch {
        print("Failed to update photo: \(error.localizedDescription)")
        self.error = error
      }

      uploadedPhoto = nil
      showPhotoEditSheet = false
    }
  }

  private func deleteExhibition() {
    guard isOrganizer else { return }

    isDeleting = true
    error = nil

    Task {
      do {
        try await exhibitionsClient.delete(id: exhibition.id)
        shouldDismiss = true
      } catch {
        self.error = error
      }
      isDeleting = false
      showDeleteConfirmation = false
    }
  }

  // PhotoDetailStoreDelegateの実装
  func photoDetailStore(_ store: PhotoDetailStore, didUpdatePhoto photo: Photo) {
    // 写真リストを更新
    if let index = photos.firstIndex(where: { $0.id == photo.id }) {
      photos[index] = photo
    }

    // 選択中の写真も更新
    if selectedPhoto?.id == photo.id {
      selectedPhoto = photo
    }
  }

  func photoDetailStore(
    _ store: PhotoDetailStore, didDeletePhoto photoId: String
  ) {
    // 写真リストから削除
    photos.removeAll(where: { $0.id == photoId })

    // 選択中の写真をクリア
    if selectedPhoto?.id == photoId {
      selectedPhoto = nil
    }
  }

  // ExhibitionEditStoreDelegateの実装
  func didSaveExhibition() {
    // 展示会情報を再読み込み
    send(.reloadExhibition)
  }

  func didCancelExhibition() {
    // 何もしない
  }

  private func reloadExhibition() {
    Task {
      do {
        let updatedExhibition = try await exhibitionsClient.get(
          id: exhibition.id)
        self.exhibition = updatedExhibition

        // カバー画像も再読み込み
        coverImageURL = nil
        send(.loadCoverImage)
      } catch {
        print("Failed to reload exhibition: \(error.localizedDescription)")
        self.error = error
      }
    }
  }

  private func movePhoto() {
    guard isOrganizer else { return }

    // 新しい順番をFirestoreに保存
    Task {
      do {
        for (index, photo) in photos.enumerated() {
          try await photoClient.updatePhotoSort(
            exhibitionId: exhibition.id,
            photoId: photo.id,
            sort: index
          )
        }
      } catch {
        print("Failed to update photo sort: \(error.localizedDescription)")
        self.error = error
      }
    }
  }

  private func showOrganizerProfile() {
    organizerProfileStore = OrganizerProfileStore(
      organizer: exhibition.organizer,
      exhibitionsClient: exhibitionsClient,
      imageCache: imageCache,
      analyticsClient: analyticsClient,
      photoClient: photoClient,
      currentUserClient: currentUserClient,
      storageClient: storageClient
    )
    isOrganizerProfileShown = true
  }

  private func recordFootprint() {
    // 自動的に足跡を記録する機能は使わないため、空のメソッドにします
  }

  private func loadFootprints() {
    guard isOrganizer else { return }

    isLoadingFootprints = true

    Task {
      do {
        // 訪問者数を取得
        visitorCount = try await footprintClient.getVisitorCount(exhibitionId: exhibition.id)
      } catch {
        logger.error("Failed to load footprints: \(error.localizedDescription)")
        self.error = error
      }

      isLoadingFootprints = false
    }
  }

  private func loadMoreFootprints() {
    // 何もしない - この機能は FootprintsListStore に移動しました
  }

  private func toggleFootprint() {
    guard let currentUser = currentUserClient.currentUser() else { return }

    isTogglingFootprint = true

    Task {
      do {
        hasAddedFootprint = try await footprintClient.toggleFootprint(
          exhibitionId: exhibition.id,
          userId: currentUser.uid
        )

        // 足跡の状態が変わったので、訪問者数を更新
        visitorCount = try await footprintClient.getVisitorCount(exhibitionId: exhibition.id)

        // 主催者の場合は足跡リストも更新
        if isOrganizer {
          loadFootprints()
        }
      } catch {
        logger.error("Failed to toggle footprint: \(error.localizedDescription)")
        self.error = error
      }

      isTogglingFootprint = false
    }
  }

  private func showFootprintsList() {
    if isOrganizer {
      footprintsListStore = FootprintsListStore(
        exhibitionId: exhibition.id,
        footprintClient: footprintClient,
        delegate: self
      )
      isShowFootprintsList = true
    }
  }

  // MARK: - FootprintsListStoreDelegate

  func footprintsListDidClose() {
    isShowFootprintsList = false
  }
}

#if !SKIP
  extension Photo: Transferable {
    static var transferRepresentation: some TransferRepresentation {
      CodableRepresentation(for: Photo.self, contentType: .photo)
    }
  }

  extension UTType {
    static let photo: UTType = .init(filenameExtension: "px")!
  }
#endif

struct ExhibitionDetailView: View {
  @Bindable var store: ExhibitionDetailStore
  @Environment(\.dismiss) private var dismiss

  @State private var draggingItem: Photo?

  init(store: ExhibitionDetailStore) {
    self.store = store
  }

  var body: some View {
    ScrollView {
      // 写真グリッド表示
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)], spacing: 8
      ) {
        Section {
          if store.isLoadingPhotos {
            ProgressView()
              .frame(maxWidth: .infinity)
          } else if store.photos.isEmpty {
            Text("No photos yet")
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.vertical)
          } else {
            ForEach(store.photos) { photo in
              if let path = photo.imagePath {
                if store.isOrganizer {
                  makeGridItem(photo, path: path)
                    #if !SKIP
                      .draggable(photo) {
                        /// custom preview
                        PhotoGridItem(
                          photo: photo,
                          path: path,
                          isOrganizer: store.isOrganizer,
                          onTap: {}
                        )
                        .frame(width: 100, height: 100)
                        .onAppear {
                          draggingItem = photo
                        }
                      }
                      .dropDestination(
                        for: Photo.self,
                        action: { items, location in
                          store.send(.moveCompleted)
                          draggingItem = nil
                          return false
                        },
                        isTargeted: { status in
                          if let draggingItem, status, draggingItem != photo {
                            if let sourceIndex = store.photos.firstIndex(where: {
                              $0 == draggingItem
                            }),
                              let destinationIndex = store.photos.firstIndex(where: { $0 == photo })
                            {
                              withAnimation(
                                .bouncy,
                                {
                                  let sourceItem = store.photos.remove(at: sourceIndex)
                                  store.photos.insert(sourceItem, at: destinationIndex)
                                })
                            }
                          }
                        }
                      )
                    #endif
                } else {
                  makeGridItem(photo, path: path)
                }
              }
            }
          }
        } header: {
          VStack(alignment: .leading, spacing: 16) {
            // Cover Image
            if let coverImageURL = store.coverImageURL {
              AsyncImage(url: coverImageURL) { phase in
                switch phase {
                case .success(let image):
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipped()
                default:
                  ProgressView()
                }
              }
            } else if store.exhibition.coverImagePath != nil {
              // 画像パスがある読み込みはローディングを表示
              ProgressView()
            }

            // Exhibition details
            VStack(alignment: .leading, spacing: 8) {
              Text(store.exhibition.name)
                .font(.largeTitle)
                .fontWeight(.bold)

              if let description = store.exhibition.description {
                Text(description)
                  .font(.body)
                  .padding(.top, 4)
              }
            }

            Divider()

            // Date information
            VStack(alignment: .leading, spacing: 8) {
              Label("Period", systemImage: SystemImageMapping.getIconName(from: "calendar"))
                .font(.headline)

              Text(formatDateRange(from: store.exhibition.from, to: store.exhibition.to))
                .font(.subheadline)
            }

            // Organizer information
            if let name = store.exhibition.organizer.name {
              Divider()
              Button {
                store.send(.showOrganizerProfile)
              } label: {
                VStack(alignment: .leading, spacing: 8) {
                  Label("Organizer", systemImage: SystemImageMapping.getIconName(from: "person"))
                    .font(.headline)
                  Text(name)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
              .buttonStyle(.plain)
            }

            // Footprints section (for organizer only)
            if store.isOrganizer {
              Divider()

              VStack(alignment: .leading, spacing: 12) {
                Button {
                  store.send(.showFootprintsListTapped)
                } label: {
                  HStack {
                    HStack(spacing: 4) {
                      #if SKIP
                        Image("shoeprints.fill", bundle: .module)
                      #else
                        Image(systemName: "shoeprints.fill")
                      #endif
                      Text("Footprints")
                    }

                    Spacer()

                    Text(store.visitorCount > 0 ? "\(store.visitorCount)" : "No visitors yet")
                      .font(.subheadline)
                      .foregroundStyle(.secondary)

                    Image(systemName: SystemImageMapping.getIconName(from: "chevron.right"))
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                  }
                  #if !SKIP
                    .contentShape(Rectangle())
                  #endif
                }
                .buttonStyle(.plain)
              }
            } else {
              // 一般ユーザー向けの足跡セクション
              Divider()

              VStack(alignment: .leading, spacing: 12) {
                HStack {
                  HStack(spacing: 4) {
                    #if SKIP
                      Image("shoeprints.fill", bundle: .module)
                    #else
                      Image(systemName: "shoeprints.fill")
                    #endif
                    Text("Footprints")
                  }

                  Spacer()

                  HStack(spacing: 8) {
                    // 足跡の追加/削除ボタン
                    Button {
                      store.send(.toggleFootprint)
                    } label: {
                      HStack {
                        if store.hasAddedFootprint {
                          Text("Remove Footprint")
                        } else {
                          Text("Add Footprint")
                        }
                      }
                      .padding(8)
                      .foregroundStyle(store.hasAddedFootprint ? Color.gray : Color.accentColor)
                      .clipShape(RoundedRectangle(cornerRadius: 8))
                      .overlay {
                        RoundedRectangle(cornerRadius: 8)
                          .stroke(
                            store.hasAddedFootprint ? Color.gray : Color.accentColor,
                            style: StrokeStyle(lineWidth: 1))
                      }
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isTogglingFootprint)
                    .overlay {
                      if store.isTogglingFootprint {
                        ProgressView()
                      }
                    }

                    Text("\(store.visitorCount) visitors")
                      .font(.subheadline)
                  }
                }
              }
            }

            // Photos section
            Divider()
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                #if SKIP
                  HStack(spacing: 8) {
                    Image("photo.on.rectangle", bundle: .module)
                    Text("Photos")
                  }
                #else
                  Label(
                    "Photos",
                    systemImage: SystemImageMapping.getIconName(from: "photo.on.rectangle")
                  )
                  .font(.headline)
                #endif

                Spacer()

                if store.isOrganizer {
                  if store.isUploadingPhoto {
                    ProgressView()
                  }

                  Button {
                    store.send(.addPhotoButtonTapped)
                  } label: {
                    Label("Add", systemImage: SystemImageMapping.getIconName(from: "plus"))
                      .font(.subheadline)
                  }
                  .disabled(store.photos.count >= maxExhibitionPhotos || store.isUploadingPhoto)
                }
              }
            }
          }
        }
      }
      .padding()
    }
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        if store.isOrganizer {
          Menu {
            Button {
              store.send(.editExhibition)
            } label: {
              Label(
                "Edit",
                systemImage: SystemImageMapping.getIconName(from: "pencil"))
            }

            Button(role: .destructive) {
              store.send(.deleteExhibition)
            } label: {
              Label(
                "Delete",
                systemImage: SystemImageMapping.getIconName(from: "trash"))
            }
          } label: {
            Image(systemName: SystemImageMapping.getIconName(from: "ellipsis"))
              .accessibilityLabel("More options")
          }
        } else {
          Button {
            store.send(.reportButtonTapped)
          } label: {
            Image(systemName: SystemImageMapping.getIconName(from: "exclamationmark.triangle"))
              .accessibilityLabel("Report exhibition")
          }
        }
      }
    }
    .sheet(isPresented: $store.showEditSheet) {
      if let store = store.exhibitionEditStore {
        ExhibitionEditView(
          store: store
        )
      }
    }
    .fullScreenCover(isPresented: $store.showPhotoDetail) {
      if let store = store.photoDetailStore {
        PhotoDetailView(store: store)
      }
    }
    .sheet(isPresented: $store.showPhotoEditSheet) {
      if let photo = store.uploadedPhoto {
        PhotoEditView(
          title: photo.title ?? "",
          description: photo.description ?? ""
        ) { title, description in
          store.send(
            .updateUploadedPhoto(title: title, description: description))
        }
        .onDisappear {
          if store.showPhotoEditSheet {
            store.send(.cancelPhotoEdit)
          }
        }
      }
    }
    .alert("Delete Exhibition", isPresented: $store.showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {
        store.send(.cancelDelete)
      }
      Button("Delete", role: .destructive) {
        store.send(.confirmDelete)
      }
      .disabled(store.isDeleting)
    } message: {
      Text(
        "Are you sure you want to delete this exhibition? This action cannot be undone."
      )
    }
    .onChange(of: store.shouldDismiss) { _, shouldDismiss in
      if shouldDismiss {
        dismiss()
      }
    }
    .navigationDestination(isPresented: $store.isOrganizerProfileShown) {
      if let organizerProfileStore = store.organizerProfileStore {
        OrganizerProfileView(store: organizerProfileStore)
      }
    }
    .task {
      store.send(.checkPermissions)
      store.send(.loadCoverImage)
      store.send(.loadPhotos)
      if store.isOrganizer {
        store.send(.loadFootprints)
      }
    }
    #if SKIP
      .withMediaPicker(
        type: MediaPickerType.library,
        isPresented: $store.photoPickerPresented,
        selectedImageURL: Binding(
          get: { store.selectedPhotoURL },
          set: { store.send(.photoSelected($0)) }
        )
      )
    #else
      .photosPicker(
        isPresented: $store.photoPickerPresented,
        selection: Binding(
          get: { nil },
          set: { item in
            if let item = item {
              Task {
                do {
                  if let data = try await item.loadTransferable(type: Data.self) {
                    #if !SKIP
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
                        store.isErrorAlertPresented = true
                        return
                      }
                    #else
                      // Skip環境では対応しない（拡張子の処理はSkipKit内で行われる）
                      let ext = "jpg"
                    #endif
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                      UUID().uuidString + "." + ext)
                    try data.write(to: tempURL)
                    store.send(.photoSelected(tempURL))
                  }
                } catch {
                  logger.error("error \(error.localizedDescription)")
                  store.error = error
                  store.isErrorAlertPresented = true
                }
              }
            }
          }
        ))
    #endif
    .sheet(isPresented: $store.showReport) {
      if let reportStore = store.reportStore {
        ReportView(store: reportStore)
      }
    }
    .alert("Error", isPresented: $store.isErrorAlertPresented) {
      Button("OK", role: .cancel) {
        store.send(.dismissError)
      }
    } message: {
      Text(store.error?.localizedDescription ?? "An error occurred")
    }
    .sheet(isPresented: $store.isShowFootprintsList) {
      if let footprintsListStore = store.footprintsListStore {
        FootprintsListView(store: footprintsListStore)
      }
    }
  }

  private func makeGridItem(_ photo: Photo, path: String) -> PhotoGridItem {
    PhotoGridItem(
      photo: photo,
      path: path,
      isOrganizer: store.isOrganizer,
      onTap: {
        store.send(.photoTapped(photo))
      }
    )
  }

  private func formatDateRange(from: Date, to: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short

    return
      "\(dateFormatter.string(from: from)) - \(dateFormatter.string(from: to))"
  }
}

// 写真グリッドアイテム
struct PhotoGridItem: View {
  let photo: Photo
  let path: String
  let isOrganizer: Bool
  let onTap: () -> Void

  @State private var imageURL: URL? = nil
  @State private var isLoading: Bool = true

  private let imageCache: StorageImageCacheProtocol = StorageImageCache.shared

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Button {
        onTap()
      } label: {
        Color.gray
          .aspectRatio(1, contentMode: .fill)
          .overlay {
            AsyncImage(url: imageURL) { phase in
              switch phase {
              case .empty:
                ZStack {
                  Rectangle()
                    .fill(Color.gray.opacity(0.2))

                  if isLoading {
                    ProgressView()
                  }
                }
              case .success(let image):
                image
                  .resizable()
                  .scaledToFill()
              case .failure:
                ZStack {
                  Rectangle()
                    .fill(Color.gray.opacity(0.2))

                  Image(
                    systemName: SystemImageMapping.getIconName(from: "exclamationmark.triangle")
                  )
                  .foregroundStyle(.secondary)
                }
              @unknown default:
                EmptyView()
              }
            }
          }
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .buttonStyle(.plain)

      // タイトルがある場合は小さなインジケータを表示
      if photo.title != nil || photo.description != nil {
        #if SKIP
          Image("text.document", bundle: .module)
            .font(.caption)
            .padding(4)
            .foregroundStyle(.white)
            .background(Circle().fill(Color.black.opacity(0.5)))
            .padding(4)
        #else
          if #available(iOS 18.0, *) {
            Image(systemName: "text.document")
              .font(.caption)
              .padding(4)
              .foregroundStyle(.white)
              .background(Circle().fill(Color.black.opacity(0.5)))
              .padding(4)
          } else {
            Image(systemName: "doc.text")
              .font(.caption)
              .padding(4)
              .foregroundStyle(.white)
              .background(Circle().fill(Color.black.opacity(0.5)))
              .padding(4)
          }
        #endif
      }
    }
    .task {
      isLoading = true
      do {
        imageURL = try await imageCache.getImageURL(for: path)
      } catch {
        print("Failed to load photo: \(error.localizedDescription)")
      }
      isLoading = false
    }
  }
}

#Preview {
  NavigationStack {
    ExhibitionDetailView(
      store: ExhibitionDetailStore(
        exhibition: Exhibition(
          id: "preview",
          name: "Sample Exhibition",
          description:
            "This is a sample exhibition description that shows how the detail view will look with a longer text. It includes information about the exhibition theme and content.",
          from: Date(),
          to: Date().addingTimeInterval(60 * 60 * 24 * 7),
          organizer: Member(
            id: "organizer1",
            name: "John Doe",
            icon: nil,
            icon_256x256: nil,
            icon_512x512: nil,
            icon_1024x1024: nil,
            createdAt: Date(),
            updatedAt: Date()
          ),
          coverImagePath: nil,
          cover_256x256: nil,
          cover_512x512: nil,
          cover_1024x1024: nil,
          createdAt: Date(),
          updatedAt: Date()
        )
      )
    )
  }
}
