import Foundation
import SkipKit
import SwiftUI

#if canImport(Photos)
  import Photos
  import PhotosUI
#endif

#if canImport(Observation)
  import Observation
#endif

// 展示会の写真の最大枚数
private let maxExhibitionPhotos = 30

@Observable
final class ExhibitionDetailStore: Store, PhotoDetailStoreDelegate,
  ExhibitionEditStoreDelegate
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

  // PhotoDetailStoreを保持
  private(set) var photoDetailStore: PhotoDetailStore?

  var showReport: Bool = false
  private(set) var reportStore: ReportStore?

  private let exhibitionsClient: ExhibitionsClient
  private let currentUserClient: CurrentUserClient
  private let storageClient: StorageClient
  let imageCache: StorageImageCacheProtocol
  let photoClient: PhotoClient

  var exhibitionEditStore: ExhibitionEditStore?

  init(
    exhibition: Exhibition,
    exhibitionsClient: ExhibitionsClient = DefaultExhibitionsClient(),
    currentUserClient: CurrentUserClient = DefaultCurrentUserClient(),
    storageClient: StorageClient = DefaultStorageClient(),
    imageCache: StorageImageCacheProtocol = StorageImageCache.shared,
    photoClient: PhotoClient = DefaultPhotoClient()
  ) {
    self.exhibition = exhibition
    self.exhibitionsClient = exhibitionsClient
    self.currentUserClient = currentUserClient
    self.storageClient = storageClient
    self.imageCache = imageCache
    self.photoClient = photoClient

    // Check if current user is the organizer
    if let currentUser = currentUserClient.currentUser() {
      self.isOrganizer = currentUser.uid == exhibition.organizer.id
    }
  }

  func send(_ action: Action) {
    switch action {
    case .checkPermissions:
      checkIfUserIsOrganizer()
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
    }
  }

  private func checkIfUserIsOrganizer() {
    if let currentUser = currentUserClient.currentUser() {
      isOrganizer = currentUser.uid == exhibition.organizer.id
    } else {
      isOrganizer = false
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
          path: photoPath,
          sort: photos.count
        )

        // 写真をStorageにアップロード
        do {
          try await storageClient.upload(from: url, to: photoPath)

          // 新しい写真を追加
          photos.append(initialPhoto)

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
              VStack(alignment: .leading, spacing: 8) {
                Label("Organizer", systemImage: SystemImageMapping.getIconName(from: "person"))
                  .font(.headline)
                Text(name)
                  .font(.subheadline)
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
    .task {
      store.send(.checkPermissions)
      store.send(.loadCoverImage)
      store.send(.loadPhotos)
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
                if let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
                {
                  let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                    UUID().uuidString + ".jpg")
                  if let imageData = image.jpegData(compressionQuality: 0.8) {
                    try? imageData.write(to: tempURL)
                    store.send(.photoSelected(tempURL))
                  }
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
