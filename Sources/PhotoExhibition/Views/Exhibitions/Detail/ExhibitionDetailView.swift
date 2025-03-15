import Foundation
import SkipKit
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

// 展示会の写真の最大枚数
private let maxExhibitionPhotos = 30

@Observable
final class ExhibitionDetailStore: Store {
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
    case deletePhoto(String)
    case confirmDeletePhoto(String)
    case cancelDeletePhoto
  }

  let exhibition: Exhibition
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
  var showDeletePhotoConfirmation: Bool = false

  private let exhibitionsClient: ExhibitionsClient
  private let currentUserClient: CurrentUserClient
  private let storageClient: StorageClient
  private let imageCache: StorageImageCacheProtocol
  private let photoClient: PhotoClient

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
    case .deletePhoto(let photoId):
      photoToDelete = photoId
      showDeletePhotoConfirmation = true
    case .confirmDeletePhoto(let photoId):
      deletePhoto(photoId: photoId)
    case .cancelDeletePhoto:
      photoToDelete = nil
      showDeletePhotoConfirmation = false
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
    guard let coverImagePath = exhibition.coverImagePath else { return }

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
        self.photos = try await photoClient.fetchPhotos(exhibitionId: exhibition.id)
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
        // 写真をStorageにアップロード
        let photoPath = "exhibitions/\(exhibition.id)/photos/\(UUID().uuidString)"
        let storageURL = try await storageClient.upload(from: url, to: photoPath)

        // 写真情報をFirestoreに保存
        let photo = try await photoClient.addPhoto(exhibitionId: exhibition.id, path: photoPath)

        // 新しい写真を追加
        photos.insert(photo, at: 0)
      } catch {
        print("Failed to upload photo: \(error.localizedDescription)")
        self.error = error
      }

      isUploadingPhoto = false
    }
  }

  private func deletePhoto(photoId: String) {
    guard isOrganizer, let photoIndex = photos.firstIndex(where: { $0.id == photoId }) else {
      showDeletePhotoConfirmation = false
      photoToDelete = nil
      return
    }

    let photo = photos[photoIndex]

    Task {
      do {
        // Firestoreから写真情報を削除
        try await photoClient.deletePhoto(exhibitionId: exhibition.id, photoId: photoId)

        // Storageから写真を削除
        if let path = photo.path {
          try await storageClient.delete(path: path)
        }

        // 写真リストから削除
        photos.remove(at: photoIndex)
      } catch {
        print("Failed to delete photo: \(error.localizedDescription)")
        self.error = error
      }

      showDeletePhotoConfirmation = false
      photoToDelete = nil
    }
  }

  private func deleteExhibition() {
    guard isOrganizer else { return }

    isDeleting = true

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
}

struct ExhibitionDetailView: View {
  @Bindable var store: ExhibitionDetailStore
  @Environment(\.dismiss) private var dismiss

  init(exhibition: Exhibition) {
    self.store = ExhibitionDetailStore(exhibition: exhibition)
  }

  var body: some View {
    ScrollView {
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
          Label("Period", systemImage: "calendar")
            .font(.headline)

          Text(formatDateRange(from: store.exhibition.from, to: store.exhibition.to))
            .font(.subheadline)
        }

        // Organizer information
        if let name = store.exhibition.organizer.name {
          Divider()
          VStack(alignment: .leading, spacing: 8) {
            Label("Organizer", systemImage: "person")
              .font(.headline)
            Text(name)
              .font(.subheadline)
          }
        }

        // Photos section
        Divider()
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Label("Photos", systemImage: "photo.on.rectangle")
              .font(.headline)

            Spacer()

            if store.isOrganizer {
              Button {
                store.send(.addPhotoButtonTapped)
              } label: {
                Label("Add", systemImage: "plus")
                  .font(.subheadline)
              }
              .disabled(store.photos.count >= maxExhibitionPhotos || store.isUploadingPhoto)
            }
          }

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
            // 写真グリッド表示
            LazyVGrid(
              columns: [GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)], spacing: 8
            ) {
              ForEach(store.photos) { photo in
                if let path = photo.path {
                  PhotoGridItem(path: path, isOrganizer: store.isOrganizer) {
                    store.send(.deletePhoto(photo.id))
                  }
                }
              }
            }
          }

          if store.isUploadingPhoto {
            HStack {
              ProgressView()
              Text("Uploading photo...")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
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
              Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
              store.send(.deleteExhibition)
            } label: {
              Label("Delete", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
    }
    .sheet(isPresented: $store.showEditSheet) {
      ExhibitionEditView(store: ExhibitionEditStore(mode: .edit(store.exhibition)))
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
      Text("Are you sure you want to delete this exhibition? This action cannot be undone.")
    }
    .alert("Delete Photo", isPresented: $store.showDeletePhotoConfirmation) {
      Button("Cancel", role: .cancel) {
        store.send(.cancelDeletePhoto)
      }
      if let photoId = store.photoToDelete {
        Button("Delete", role: .destructive) {
          store.send(.confirmDeletePhoto(photoId))
        }
      }
    } message: {
      Text("Are you sure you want to delete this photo? This action cannot be undone.")
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
    .withMediaPicker(
      type: MediaPickerType.library,
      isPresented: $store.photoPickerPresented,
      selectedImageURL: Binding(
        get: { store.selectedPhotoURL },
        set: { store.send(.photoSelected($0)) }
      )
    )
  }

  private func formatDateRange(from: Date, to: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short

    return "\(dateFormatter.string(from: from)) - \(dateFormatter.string(from: to))"
  }
}

// 写真グリッドアイテム
struct PhotoGridItem: View {
  let path: String
  let isOrganizer: Bool
  let onDelete: () -> Void

  @State private var imageURL: URL? = nil
  @State private var isLoading: Bool = true

  private let imageCache: StorageImageCacheProtocol = StorageImageCache.shared

  var body: some View {
    ZStack(alignment: .topTrailing) {
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
            .aspectRatio(contentMode: .fill)
        case .failure:
          ZStack {
            Rectangle()
              .fill(Color.gray.opacity(0.2))

            Image(systemName: "exclamationmark.triangle")
              .foregroundStyle(.secondary)
          }
        @unknown default:
          EmptyView()
        }
      }
      .aspectRatio(1, contentMode: .fill)
      .frame(minWidth: 100, minHeight: 100)
      .clipShape(RoundedRectangle(cornerRadius: 8))

      if isOrganizer {
        Button {
          onDelete()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.white)
            .background(Circle().fill(Color.black.opacity(0.5)))
        }
        .padding(4)
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
          createdAt: Date(),
          updatedAt: Date()
        ),
        coverImagePath: nil,
        createdAt: Date(),
        updatedAt: Date()
      )
    )
  }
}
