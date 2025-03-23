import SwiftUI

#if canImport(Observation)
  import Observation
#endif

struct StaggeredGrid<Content: View, T: Identifiable>: View where T: Hashable {

  // MARK: - Properties
  var content: (T) -> Content
  var list: [T]
  var columns: Int
  var showIndicators: Bool
  var spacing: CGFloat

  init(
    list: [T], columns: Int, showIndicators: Bool = false,
    spacing: CGFloat = 0, @ViewBuilder content: @escaping (T) -> Content
  ) {
    self.content = content
    self.list = list
    self.columns = columns
    self.showIndicators = showIndicators
    self.spacing = spacing
  }

  func setUpList() -> [[T]] {
    var gridArray: [[T]] = Array(repeating: [], count: columns)
    var currentIndex: Int = 0
    for object in list {
      gridArray[currentIndex].append(object)
      if currentIndex == (columns - 1) {
        currentIndex = 0
      } else {
        currentIndex += 1
      }
    }
    return gridArray
  }

  // MARK: - Body
  var body: some View {
    ScrollView(.vertical) {
      HStack(alignment: .top) {
        ForEach(setUpList(), id: \.self) { columnData in
          LazyVStack(spacing: spacing) {
            ForEach(columnData) { object in
              content(object)
            }
          }
        }
      }
      .padding(8)
    }
  }
}

struct ExhibitionCardView: View {
  private let imageCache: any StorageImageCacheProtocol
  @State var isLoadingImage: Bool = false
  @State var coverImageURL: URL?
  let exhibition: Exhibition

  init(
    exhibition: Exhibition,
    imageCache: any StorageImageCacheProtocol = StorageImageCache(
      storageClient: DefaultStorageClient.shared)
  ) {
    self.exhibition = exhibition
    self.imageCache = imageCache
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Group {
        if let coverImageURL {
          AsyncImage(url: coverImageURL) { phase in
            switch phase {
            case .empty:
              ProgressView()
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            default:
              ProgressView()
            }
          }
        } else if exhibition.coverImagePath != nil {
          ProgressView()
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))

      Text(exhibition.name)
        .font(.headline)

      if let description = exhibition.description {
        Text(description)
          .font(.subheadline)
          .lineLimit(2)
      }

      Text(formatDateRange(from: exhibition.from, to: exhibition.to))
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(8)
    .task {
      await loadCoverImage()
    }
  }

  private func formatDateRange(from: Date, to: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return "\(formatter.string(from: from)) - \(formatter.string(from: to))"
  }

  private func loadCoverImage() async {
    guard let coverImagePath = exhibition.coverPath else { return }

    isLoadingImage = true

    do {
      let localURL = try await imageCache.getImageURL(for: coverImagePath)
      self.coverImageURL = localURL
    } catch {
      print("Failed to load cover image: \(error.localizedDescription)")
    }

    isLoadingImage = false
  }
}

struct ExhibitionsView: View {
  @Bindable private var store: ExhibitionsStore
  init(store: ExhibitionsStore) {
    self.store = store
  }

  var body: some View {
    NavigationStack {
      Group {
        if store.isLoading && store.exhibitions.isEmpty {
          ProgressView()
        } else if store.exhibitions.isEmpty {
          #if SKIP
            HStack(spacing: 8) {
              Image("photo.on.rectangle", bundle: .module)
              Text("No Exhibitions")
            }
          #else
            ContentUnavailableView(
              "No Exhibitions",
              systemImage: SystemImageMapping.getIconName(
                from: "photo.on.rectangle"),
              description: Text("Create a new exhibition")
            )
          #endif
        } else {
          StaggeredGrid(list: store.exhibitions, columns: 2) { exhibition in
            Button {
              store.send(.showExhibitionDetail(exhibition))
            } label: {
              ExhibitionCardView(exhibition: exhibition)
            }
            .buttonStyle(.plain)
          }
          .refreshable {
            store.send(.refresh)
          }
        }
      }
      .navigationTitle(Text("Exhibitions"))
      .navigationDestination(isPresented: $store.isExhibitionDetailShown) {
        if let detailStore = store.exhibitionDetailStore {
          ExhibitionDetailView(store: detailStore)
        }
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            store.send(.createExhibition)
          } label: {
            Image(systemName: SystemImageMapping.getIconName(from: "plus"))
              .accessibilityLabel("Create a new exhibition")
          }
        }
      }
      .task {
        store.send(.task)
      }
      .sheet(isPresented: $store.showCreateExhibition) {
        if let editStore = store.exhibitionEditStore {
          ExhibitionEditView(store: editStore)
        }
      }
      .sheet(item: $store.exhibitionToEdit) { exhibition in
        if let editStore = store.exhibitionEditStore {
          ExhibitionEditView(store: editStore)
        }
      }
    }
  }

}

struct ExhibitionRow: View {
  let exhibition: Exhibition
  let imageCache: StorageImageCacheProtocol
  @State private var coverImageURL: URL? = nil
  @State private var isLoadingImage: Bool = false

  init(
    exhibition: Exhibition,
    imageCache: StorageImageCacheProtocol = StorageImageCache.shared
  ) {
    self.exhibition = exhibition
    self.imageCache = imageCache
  }

  var body: some View {
    HStack(spacing: 12) {
      // Cover Image
      Group {
        if let coverImageURL = coverImageURL {
          AsyncImage(url: coverImageURL) { phase in
            switch phase {
            case .empty:
              ProgressView()
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            default:
              ProgressView()
            }
          }
        } else if exhibition.coverImagePath != nil {
          ProgressView()
        }
      }
      .frame(width: 60, height: 60)
      .background(Color.gray.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 8))

      // Exhibition details
      VStack(alignment: .leading, spacing: 8) {
        Text(exhibition.name)
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)

        if let description = exhibition.description {
          Text(description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        HStack {
          Label {
            Text(formatDateRange(from: exhibition.from, to: exhibition.to))
          } icon: {
            Image(systemName: SystemImageMapping.getIconName(from: "calendar"))
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
    #if !SKIP
      .contentShape(Rectangle())  // This makes the entire area tappable
    #endif
    .task {
      await loadCoverImage()
    }
  }

  private func loadCoverImage() async {
    guard let coverImagePath = exhibition.coverPath else { return }

    isLoadingImage = true

    do {
      let localURL = try await imageCache.getImageURL(for: coverImagePath)
      self.coverImageURL = localURL
    } catch {
      print("Failed to load cover image: \(error.localizedDescription)")
    }

    isLoadingImage = false
  }

  private func formatDateRange(from: Date, to: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short

    return
      "\(dateFormatter.string(from: from)) - \(dateFormatter.string(from: to))"
  }
}

#Preview {
  ExhibitionsView(store: ExhibitionsStore())
}
