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
    ZStack {
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
        isPresented: Binding(
          get: { store.exhibitionDetailStore != nil },
          set: { if !$0 { store.exhibitionDetailStore = nil } }
        )
      ) {
        if let detailStore = store.exhibitionDetailStore {
          ExhibitionDetailView(store: detailStore)
        }
      }
      .task {
        store.send(.task)
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            store.send(.addButtonTapped)
          } label: {
            Image(systemName: "plus")
          }
          .accessibilityLabel(Text("Add Exhibition"))
        }
      }
      .sheet(
        isPresented: Binding(
          get: { store.exhibitionEditStore != nil },
          set: { if !$0 { store.exhibitionEditStore = nil } }
        )
      ) {
        if let store = store.exhibitionEditStore {
          ExhibitionEditView(store: store)
        }
      }
      .disabled(store.showPostAgreement)

      if store.showPostAgreement {
        PostAgreementView(
          onAgree: {
            store.send(.postAgreementAccepted)
          },
          onDismiss: {
            store.send(.postAgreementDismissed)
          }
        )
        .transition(.opacity)
      }
    }
  }
}

#Preview {
  NavigationStack {
    MyExhibitionsView(store: MyExhibitionsStore())
  }
}
