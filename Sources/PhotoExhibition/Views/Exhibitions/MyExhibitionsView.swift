import SwiftUI

#if canImport(Observation)
  import Observation
#endif

struct MyExhibitionsView: View {
  @Bindable private var store: MyExhibitionsStore

  init(store: MyExhibitionsStore) {
    self.store = store
  }

  var body: some View {
    Group {
      if store.isLoading && store.exhibitions.isEmpty {
        ProgressView()
      } else if store.exhibitions.isEmpty {
        #if SKIP
          HStack(spacing: 8) {
            Image(systemName: SystemImageMapping.getIconName(from: "photo.on.rectangle"))
            Text("No Exhibitions")
          }
        #else
          ContentUnavailableView(
            "No Exhibitions",
            systemImage: SystemImageMapping.getIconName(from: "photo.on.rectangle"),
            description: Text("You haven't created any exhibitions yet")
          )
        #endif
      } else {
        List {
          ForEach(store.exhibitions) { exhibition in
            Button {
              store.send(.exhibitionSelected(exhibition))
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
    }
    .navigationDestination(
      isPresented: $store.isExhibitionShown
    ) {
      if let detailStore = store.exhibitionDetailStore {
        ExhibitionDetailView(store: detailStore)
      }
    }
    .task {
      store.send(.task)
    }
  }
}

#Preview {
  NavigationStack {
    MyExhibitionsView(store: MyExhibitionsStore())
  }
}
