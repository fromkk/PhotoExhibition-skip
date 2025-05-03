//
//  ContentView.swift
//  PhotoExhibitionViewer
//
//  Created by Kazuya Ueoka on 2025/04/18.
//

import SwiftUI
import Viewer

struct ContentView: View {
  let exhibitionsStore: ExhibitionsStore = .init(
    exhibitionsClient: ExhibitionsClient.liveValue,
    imageClient: StorageImageCache.shared
  )
  let menuStore: MenuStore = .init()

  var body: some View {
    TabView {
      ExhibitionsView(store: exhibitionsStore)
        .tabItem {
          Label("Exhibitions", systemImage: "photo")
        }
        .tag(1)

      MenuView(store: menuStore)
        .tabItem {
          Label("Menu", systemImage: "list.bullet")
        }
        .tag(2)
    }
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
}
