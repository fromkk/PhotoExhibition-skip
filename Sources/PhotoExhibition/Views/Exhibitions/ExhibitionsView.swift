import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class ExhibitionsStore: Store {
  enum Action {
    case task
    case refresh
    case createExhibition
    case editExhibition(Exhibition)
    case showExhibitionDetail(Exhibition)
  }

  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  var showCreateExhibition: Bool = false
  var exhibitionToEdit: Exhibition? = nil
  var selectedExhibition: Exhibition? = nil

  private let exhibitionsClient: ExhibitionsClient

  init(exhibitionsClient: ExhibitionsClient = DefaultExhibitionsClient()) {
    self.exhibitionsClient = exhibitionsClient
  }

  func send(_ action: Action) {
    switch action {
    case .task, .refresh:
      fetchExhibitions()
    case .createExhibition:
      showCreateExhibition = true
    case .editExhibition(let exhibition):
      exhibitionToEdit = exhibition
    case .showExhibitionDetail(let exhibition):
      selectedExhibition = exhibition
    }
  }

  private func fetchExhibitions() {
    isLoading = true

    Task {
      do {
        exhibitions = try await exhibitionsClient.fetch()
      } catch {
        self.error = error
      }

      isLoading = false
    }
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
              Image(systemName: "photo.on.rectangle")
              Text("No Exhibitions")
            }
          #else
            ContentUnavailableView(
              "No Exhibitions",
              systemImage: "photo.on.rectangle",
              description: Text("Create a new exhibition")
            )
          #endif
        } else {
          List {
            ForEach(store.exhibitions) { exhibition in
              NavigationLink(value: exhibition) {
                ExhibitionRow(exhibition: exhibition)
              }
            }
          }
          .refreshable {
            store.send(.refresh)
          }
        }
      }
      .navigationTitle("Exhibitions")
      .navigationDestination(for: Exhibition.self) { exhibition in
        ExhibitionDetailView(exhibition: exhibition)
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            store.send(.createExhibition)
          } label: {
            Image(systemName: "plus")
          }
        }
      }
      .task {
        store.send(.task)
      }
      .sheet(isPresented: $store.showCreateExhibition) {
        ExhibitionEditView(store: ExhibitionEditStore(mode: .create))
      }
      .sheet(item: $store.exhibitionToEdit) { exhibition in
        ExhibitionEditView(store: ExhibitionEditStore(mode: .edit(exhibition)))
      }
    }
  }
}

struct ExhibitionRow: View {
  let exhibition: Exhibition
  @State private var coverImageURL: URL? = nil
  @State private var isLoadingImage: Bool = false

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
        }
      }
      .frame(width: 60, height: 60)

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
            Image(systemName: "calendar")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
    .task {
      await loadCoverImage()
    }
  }

  private func loadCoverImage() async {
    guard let coverImagePath = exhibition.coverImagePath else { return }

    isLoadingImage = true

    do {
      let url = try await DefaultStorageClient.shared.url(coverImagePath)
      self.coverImageURL = url
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
