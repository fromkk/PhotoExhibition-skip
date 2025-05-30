import PhotoExhibitionModel
import SwiftUI

struct OrganizerProfileView: View {
  @Bindable private var store: OrganizerProfileStore

  init(store: OrganizerProfileStore) {
    self.store = store
  }

  var body: some View {
    ScrollView {
      Section {
        LazyVStack(spacing: 16) {
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
      } header: {
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
                    Image(
                      systemName: SystemImageMapping.getIconName(from: "person.crop.circle.fill")
                    )
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

            // ブロックUI - ナビゲーションバーに移動したので削除
            if store.isBlockingUser {
              ProgressView()
                .padding(.top, 4)
            }
          }
          .padding()

          // 展示会一覧
          VStack(alignment: .leading, spacing: 16) {
            Text("Exhibitions")
              .font(.headline.bold())
              .padding(.horizontal)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
    .navigationTitle("Organizer Profile")
    .navigationDestination(
      isPresented: Binding(
        get: {
          store.exhibitionDetailStore != nil
        },
        set: {
          if !$0 {
            store.exhibitionDetailStore = nil
          }
        }
      )
    ) {
      if let detailStore = store.exhibitionDetailStore {
        ExhibitionDetailView(store: detailStore)
      }
    }
    .toolbar {
      if store.canShowBlockButton {
        ToolbarItem(placement: .primaryAction) {
          Menu {
            if store.isBlocked {
              Button {
                store.send(.unblockButtonTapped)
              } label: {
                #if SKIP
                  Text("Unblock User")
                #else
                  Label("Unblock User", systemImage: "person.crop.circle.badge.checkmark")
                #endif
              }
              .disabled(store.isBlockingUser)
            } else {
              Button(role: .destructive) {
                store.send(.blockButtonTapped)
              } label: {
                #if SKIP
                  Text("Block User")
                #else
                  Label("Block User", systemImage: "person.crop.circle.badge.xmark")
                #endif
              }
              .disabled(store.isBlockingUser)
            }
          } label: {
            Image(systemName: SystemImageMapping.getIconName(from: "ellipsis"))
          }
        }
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
                #if SKIP
                  Image("photo", bundle: .module)
                    .foregroundStyle(.gray)
                #else
                  Image(systemName: "photo")
                    .foregroundStyle(.gray)
                #endif
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
          .frame(maxWidth: .infinity, alignment: .leading)

        if let description = exhibition.description {
          Text(description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
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
