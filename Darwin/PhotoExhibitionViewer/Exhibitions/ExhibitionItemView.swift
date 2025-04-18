import SwiftUI

@Observable
final class ExhibitionItemStore: Identifiable {
  var id: String { item.id ?? "" }

  init(
    exhibition: Exhibition,
    imageClient: any StorageImageCacheProtocol
  ) {
    self.item = exhibition
    self.imageClient = imageClient
  }

  var imageClient: any StorageImageCacheProtocol

  var item: Exhibition
  var imageURL: URL?
  var error: (any Error)?

  func fetch() async {
    guard let path = item.coverPath else { return }
    do {
      imageURL = try await imageClient.getImageURL(for: path)
    } catch {
      self.error = error
    }  //
  }
}

struct ExhibitionItemView: View {
  @Bindable var store: ExhibitionItemStore

  var body: some View {
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

      VStack(spacing: 8) {
        Text(store.item.name)
          .frame(maxWidth: .infinity, alignment: .leading)
          .multilineTextAlignment(.leading)
      }
      .padding()
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .task {
      await store.fetch()
    }
  }
}
