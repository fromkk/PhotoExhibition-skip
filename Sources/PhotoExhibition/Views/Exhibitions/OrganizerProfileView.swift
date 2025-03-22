import SwiftUI

struct OrganizerProfileView: View {
  @Bindable private var store: OrganizerProfileStore

  init(store: OrganizerProfileStore) {
    self.store = store
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // プロフィール情報
        VStack(spacing: 16) {
          // アイコン
          Group {
            if let iconURL = store.organizerIconURL {
              AsyncImage(url: iconURL) { phase in
                switch phase {
                case .empty:
                  ProgressView()
                    .frame(width: 100, height: 100)
                case .success(let image):
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                case .failure:
                  Image(systemName: SystemImageMapping.getIconName(from: "person.crop.circle.fill"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.gray)
                @unknown default:
                  EmptyView()
                }
              }
            } else {
              Image(systemName: SystemImageMapping.getIconName(from: "person.crop.circle.fill"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundStyle(.gray)
            }
          }
          .frame(width: 100, height: 100)

          // 名前
          Text(store.organizer.name ?? "No Name")
            .font(.title)
            .fontWeight(.bold)
        }
        .padding()

        // 展示会一覧
        VStack(alignment: .leading, spacing: 16) {
          Text("Exhibitions")
            .font(.headline)
            .padding(.horizontal)

          if store.isLoading && store.exhibitions.isEmpty {
            ProgressView()
              .frame(maxWidth: .infinity, alignment: .center)
              .padding()
          } else if store.exhibitions.isEmpty {
            #if SKIP
              HStack(spacing: 8) {
                Image("photo.on.rectangle", bundle: .module)
                Text("No Exhibitions")
              }
              .frame(maxWidth: .infinity, alignment: .center)
              .padding()
            #else
              ContentUnavailableView(
                "No Exhibitions",
                systemImage: SystemImageMapping.getIconName(from: "photo.on.rectangle"),
                description: Text("This organizer doesn't have any published exhibitions.")
              )
            #endif
          } else {
            LazyVStack(spacing: 16) {
              ForEach(store.exhibitions) { exhibition in
                Button {
                  store.send(.showExhibitionDetail(exhibition))
                } label: {
                  // ExhibitionRowの代わりにOrganizerExhibitionRowを使用
                  OrganizerExhibitionRow(exhibition: exhibition)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
              }

              if store.hasMore {
                ProgressView()
                  .onAppear {
                    store.send(.loadMoreExhibitions)
                  }
                  .padding()
              }
            }
          }
        }
      }
    }
    .background(Color("background", bundle: .module))
    .navigationTitle("Organizer Profile")
    .navigationDestination(isPresented: $store.isExhibitionDetailShown) {
      if let detailStore = store.exhibitionDetailStore {
        ExhibitionDetailView(store: detailStore)
      }
    }
    .task {
      store.send(.task)
    }
  }
}

// ExhibitionRowを参考にした、主催者プロフィールボタンのないバージョン
struct OrganizerExhibitionRow: View {
  let exhibition: Exhibition
  @State private var coverImageURL: URL? = nil
  @State private var isLoadingImage: Bool = false
  private let imageCache: StorageImageCacheProtocol

  init(exhibition: Exhibition, imageCache: StorageImageCacheProtocol = StorageImageCache.shared) {
    self.exhibition = exhibition
    self.imageCache = imageCache
  }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // Cover image
      Group {
        if let coverImageURL {
          AsyncImage(url: coverImageURL) { phase in
            switch phase {
            case .empty:
              Rectangle()
                .foregroundStyle(.gray.opacity(0.1))
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            case .failure:
              Rectangle()
                .foregroundStyle(.gray.opacity(0.1))
                .overlay {
                  Image(systemName: SystemImageMapping.getIconName(from: "photo"))
                    .foregroundStyle(.gray)
                }
            @unknown default:
              EmptyView()
            }
          }
        } else {
          Rectangle()
            .foregroundStyle(.gray.opacity(0.1))
            .overlay {
              if isLoadingImage {
                ProgressView()
              } else {
                Image(systemName: SystemImageMapping.getIconName(from: "photo"))
                  .foregroundStyle(.gray)
              }
            }
        }
      }
      .frame(width: 60, height: 60)
      .background(Color.gray.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 8))

      // Exhibition details
      VStack(alignment: .leading, spacing: 8) {
        Text(exhibition.name)
          .font(.headline)

        if let description = exhibition.description {
          Text(description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
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
  let organizer = Member(
    id: "preview",
    name: "Preview Organizer",
    icon: nil,
    icon_256x256: nil,
    icon_512x512: nil,
    icon_1024x1024: nil,
    createdAt: Date(),
    updatedAt: Date()
  )

  return NavigationStack {
    OrganizerProfileView(store: OrganizerProfileStore(organizer: organizer))
  }
}
