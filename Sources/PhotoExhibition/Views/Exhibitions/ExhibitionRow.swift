import PhotoExhibitionModel
import SwiftUI

extension ExhibitionStatus {
  public var localizedKey: LocalizedStringKey {
    LocalizedStringKey(rawValue)
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
                .aspectRatio(contentMode: .fill)
            default:
              ProgressView()
            }
          }
        } else if exhibition.coverImagePath != nil {
          ProgressView()
        }
      }
      .frame(width: 80, height: 80)
      .background(Color.gray.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 16))

      // Exhibition details
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          Text(exhibition.name)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)

          if exhibition.status != .published {
            Text(exhibition.status.localizedKey)
              .font(.subheadline)
              .foregroundStyle(Color.gray)
              .padding(.vertical, 4)
              .padding(.horizontal, 8)
              .clipShape(Capsule())
              .overlay {
                Capsule()
                  .stroke(Color.gray, style: StrokeStyle(lineWidth: 1))
              }
          }
        }

        if let description = exhibition.description {
          Text(description.linkified)
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
