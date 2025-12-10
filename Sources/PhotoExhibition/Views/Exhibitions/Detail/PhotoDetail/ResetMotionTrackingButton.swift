import SwiftUI

struct ResetMotionTrackingButton: View {
  let action: () -> Void

  var body: some View {
    Button {
      action()
    } label: {
      Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
        .padding()
        .clipShape(Circle())
        .tint(Color("text", bundle: .module))
    }
    .accessibilityLabel(Text("Use motion tracking", bundle: .module))
    #if !SKIP
    .glassEffectForiOS26()
    #endif
  }
}

#Preview {
  ResetMotionTrackingButton {}
}
