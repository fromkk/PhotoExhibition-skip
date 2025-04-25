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

  var body: some View {
    ExhibitionsView(store: exhibitionsStore)
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
}
