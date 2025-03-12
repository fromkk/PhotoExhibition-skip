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

  var body: some View {
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
    .padding(.vertical, 4)
  }

  private func formatDateRange(from: Date, to: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .none

    return "\(dateFormatter.string(from: from)) - \(dateFormatter.string(from: to))"
  }
}

#Preview {
  ExhibitionsView(store: ExhibitionsStore())
}
