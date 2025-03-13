import Foundation
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class ExhibitionDetailStore: Store {
  enum Action {
    case checkPermissions
    case editExhibition
    case deleteExhibition
    case confirmDelete
    case cancelDelete
    case loadCoverImage
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

  private let exhibitionsClient: ExhibitionsClient
  private let currentUserClient: CurrentUserClient
  private let storageClient: StorageClient
  private let imageCache: StorageImageCacheProtocol

  init(
    exhibition: Exhibition,
    exhibitionsClient: ExhibitionsClient = DefaultExhibitionsClient(),
    currentUserClient: CurrentUserClient = DefaultCurrentUserClient(),
    storageClient: StorageClient = DefaultStorageClient(),
    imageCache: StorageImageCacheProtocol = StorageImageCache.shared
  ) {
    self.exhibition = exhibition
    self.exhibitionsClient = exhibitionsClient
    self.currentUserClient = currentUserClient
    self.storageClient = storageClient
    self.imageCache = imageCache

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

        Divider()

        // Organizer information
        VStack(alignment: .leading, spacing: 8) {
          Label("Organizer", systemImage: "person")
            .font(.headline)

          Text(store.exhibition.organizer.name)
            .font(.subheadline)
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
    .onChange(of: store.shouldDismiss) { _, shouldDismiss in
      if shouldDismiss {
        dismiss()
      }
    }
    .task {
      store.send(.checkPermissions)
      store.send(.loadCoverImage)
    }
  }

  private func formatDateRange(from: Date, to: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short

    return "\(dateFormatter.string(from: from)) - \(dateFormatter.string(from: to))"
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
