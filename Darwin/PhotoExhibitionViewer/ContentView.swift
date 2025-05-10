import SwiftUI
import Viewer

enum Tab: Hashable {
  case exhibitions
  case menu
}

@Observable
final class ContentStore: Store {
  var selectedTab: Tab = .exhibitions

  let exhibitionsStore: ExhibitionsStore = .init(
    exhibitionsClient: ExhibitionsClient.liveValue,
    imageClient: StorageImageCache.shared
  )
  let menuStore: MenuStore = .init()

  enum Action {
    case onOpenURL(URL)
  }

  func send(_ action: Action) {
    switch action {
    case let .onOpenURL(url):
      // URLのパスを解析
      let pathComponents = url.pathComponents
      guard pathComponents.count == 3 && pathComponents[1] == "exhibition" else { return }

      // exhibitionIdを取得
      let exhibitionId = pathComponents[2]

      // 展示タブを選択
      selectedTab = .exhibitions

      // ExhibitionsStoreに展示会の表示を要求
      exhibitionsStore.showExhibitionDetail(exhibitionId: exhibitionId)
      return
    }
  }
}

struct ContentView: View {
  @Bindable var store: ContentStore
  init(store: ContentStore) {
    self.store = store
  }

  var body: some View {
    TabView(selection: $store.selectedTab) {
      ExhibitionsView(store: store.exhibitionsStore)
        .tabItem {
          Label("Exhibitions", systemImage: "photo")
        }
        .tag(Tab.exhibitions)

      MenuView(store: store.menuStore)
        .tabItem {
          Label("Menu", systemImage: "list.bullet")
        }
        .tag(Tab.menu)
    }
    .onOpenURL { url in
      store.send(.onOpenURL(url))
    }
  }
}

#Preview(windowStyle: .automatic) {
  ContentView(store: ContentStore())
}
