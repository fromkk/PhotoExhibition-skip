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
        .tag(1)

      MenuView(store: menuStore)
        .tag(2)
    }
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
}
