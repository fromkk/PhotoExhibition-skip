import Foundation
import SkipKit
import SwiftUI

/// 展示会の足跡（訪問者）一覧を表示するビュー
struct FootprintsListView: View {
  @Bindable var store: FootprintsListStore

  var body: some View {
    List {
      if store.isLoadingFootprints && store.footprints.isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .listRowSeparator(.hidden)
      } else if store.footprints.isEmpty {
        Text("No visitors yet")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)
          .listRowSeparator(.hidden)
      } else {
        Section {
          ForEach(store.footprints) { footprint in
            Button {
              store.send(.userTapped(userId: footprint.userId))
            } label: {
              MemberRowView(userId: footprint.userId)
                .frame(maxWidth: .infinity, alignment: .leading)
                #if !SKIP
                  .contentShape(Rectangle())
                #endif
            }
            .buttonStyle(.plain)
          }

          if store.hasMoreFootprints {
            Button {
              store.send(.loadMoreFootprints)
            } label: {
              if store.isLoadingFootprints {
                ProgressView()
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 8)
              } else {
                Text("Load more")
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 8)
              }
            }
            .buttonStyle(.plain)
          }
        } header: {
          Text("\(store.footprints.count) visitors")
        }
      }
    }
    .navigationTitle("Visitors")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Close") {
          store.send(.closeButtonTapped)
        }
      }
    }
    .task {
      store.send(.loadFootprints)
    }
    .navigationDestination(isPresented: $store.showMemberProfile) {
      if let memberProfileStore = store.memberProfileStore {
        OrganizerProfileView(store: memberProfileStore)
      }
    }
  }
}
