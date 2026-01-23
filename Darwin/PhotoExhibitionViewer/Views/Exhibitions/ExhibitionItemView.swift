import SwiftUI
import Viewer

@Observable
final class ExhibitionItemStore: Identifiable {
  var id: String { exhibition.id ?? "" }

  init(
    exhibition: Exhibition,
    imageClient: any StorageImageCacheProtocol
  ) {
    self.exhibition = exhibition
    self.imageClient = imageClient
  }

  var imageClient: any StorageImageCacheProtocol

  var exhibition: Exhibition
  var imageURL: URL?
  var error: (any Error)?

  func fetch() async {
    guard let path = exhibition.coverPath else { return }
    do {
      imageURL = try await imageClient.getImageURL(for: path)
    } catch {
      self.error = error
    }
  }
}

struct ExhibitionItemView: View {
  @Bindable var store: ExhibitionItemStore
  let tapAction: () -> Void

  var body: some View {
    Button {
      tapAction()
    } label: {
      ZStack(alignment: .bottomLeading) {
        AsyncImage(url: store.imageURL) { phase in
          switch phase {
          case let .success(image):
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
          default:
            ProgressView()
          }
        }

        LinearGradient(
          stops: [
            .init(color: .black.opacity(0), location: 0.7),
            .init(color: .black.opacity(0.5), location: 1),
          ], startPoint: .top, endPoint: .bottom)

        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 8) {
            Text(store.exhibition.name)
              .font(.headline)
              .frame(maxWidth: .infinity, alignment: .leading)

            if store.exhibition.status != .published {
              Text(store.exhibition.status.localizedKey)
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

          if let description = store.exhibition.description {
            Text(description)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          HStack {
            Label {
              Text(formatDateRange(from: store.exhibition.from, to: store.exhibition.to))
            } icon: {
              Image(systemName: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
          }
        }
        .padding()
      }
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .task {
      await store.fetch()
    }
  }

  private func formatDateRange(from: Date, to: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short

    return "\(dateFormatter.string(from: from)) - \(dateFormatter.string(from: to))"
  }
}
