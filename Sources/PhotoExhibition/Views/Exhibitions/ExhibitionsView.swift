import SwiftUI

#if canImport(Observation)
  import Observation
#endif

#if !os(Android)
import GoogleMobileAds
#endif

struct ExhibitionsView: View {
  @Bindable private var store: ExhibitionsStore
  init(store: ExhibitionsStore) {
    self.store = store
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 8) {
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
              systemImage: SystemImageMapping.getIconName(from: "photo.on.rectangle"),
              description: Text("Create a new exhibition")
            )
          #endif
        } else {
          List {
            ForEach(store.exhibitions) { exhibition in
              Button {
                store.send(.showExhibitionDetail(exhibition))
              } label: {
                ExhibitionRow(exhibition: exhibition)
              }
              .buttonStyle(.plain)
            }

            if store.hasMore {
              ProgressView()
                .onAppear {
                  store.send(.loadMore)
                }
            }
          }
          .refreshable {
            store.send(.refresh)
          }
        }

        #if !os(Android)
        BannerContentView(adUnitId: Constants.adMobHomeFooterUnitID)
        #endif
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

  init(exhibition: Exhibition, imageCache: StorageImageCacheProtocol = StorageImageCache.shared) {
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

    return "\(dateFormatter.string(from: from)) - \(dateFormatter.string(from: to))"
  }
}

#Preview {
  ExhibitionsView(store: ExhibitionsStore())
}
