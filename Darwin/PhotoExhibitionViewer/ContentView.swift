//
//  ContentView.swift
//  PhotoExhibitionViewer
//
//  Created by Kazuya Ueoka on 2025/04/18.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct ContentView: View {
  let exhibitionsStore: ExhibitionsStore = .init(
    exhibitionsClient: ExhibitionsClient.liveValue,
    imageClient: StorageImageCache.shared
  )

  var body: some View {
    VStack {
      Image(.logo)

      ExhibitionsView(store: exhibitionsStore)
    }
    .padding()
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
}
