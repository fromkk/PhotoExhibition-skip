import SwiftUI

struct CrossPlatformAsyncImage<Content: View>: View {
  let url: URL?
  let animation: Animation?
  @ViewBuilder let content: (AsyncImagePhase) -> Content

  init(
    url: URL?, animation: Animation?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
  ) {
    self.url = url
    self.animation = animation
    self.content = content
  }

  var body: some View {
    #if SKIP
      AsyncImage(url: url, content: content)
    #else
      AsyncImage(url: url, transaction: Transaction(animation: animation), content: content)
    #endif
  }
}
