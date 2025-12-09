#if !SKIP

import SwiftUI

extension View {
  @ViewBuilder
  func glassEffectForiOS26() -> some View {
    if #available(iOS 26.0, *) {
      self
        .glassEffect()
    } else {
      self
    }
  }
}

#endif
