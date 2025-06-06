import SwiftUI

struct DelayAppearModifier: ViewModifier {
  let offset: CGFloat

  @State var isShown: Bool = false

  func body(content: Content) -> some View {
    content
      .opacity(isShown ? 1.0 : 0.0)
      .offset(x: 0.0, y: isShown ? 0.0 : offset)
      .task {
        isShown = true
      }
      .animation(.default.delay(0.1), value: isShown)
  }
}
