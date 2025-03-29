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
    ZStack {
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
            if store.isLoadingMember {
              ProgressView()
            } else {
              Button {
                store.send(.createExhibitionButtonTapped)
              } label: {
                Image(systemName: SystemImageMapping.getIconName(from: "plus"))
                  .accessibilityLabel("Create a new exhibition")
              }
            }
          }
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
      .disabled(store.showPostAgreement)
      .task {
        store.send(.task)
      }

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
  ExhibitionsView(store: ExhibitionsStore())
}
