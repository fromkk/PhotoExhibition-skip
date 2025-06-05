import SwiftUI

public struct LaunchingView: View {
  @State private var rotationAngle: Double = 0.0
  @Environment(\.colorScheme) var colorScheme

  var backgroundColor: Color {
    if colorScheme == .dark {
      return .black
    } else {
      return .white
    }
  }

  var foregroundColor: Color {
    if colorScheme == .dark {
      return .white
    } else {
      return .black
    }
  }

  public init() {}

  public var body: some View {
    ZStack(alignment: .center) {
      Rectangle()
        .stroke(foregroundColor, style: StrokeStyle(lineWidth: 20))
        .fill(.clear)
        .frame(width: 200, height: 200)

      Circle()
        .fill(backgroundColor)
        .frame(width: 200, height: 200)
        .offset(x: sqrt(2) * 100, y: 0)  // 半径 = 100√2 ≈ 141.42（右上の角までの距離）
        .rotationEffect(.degrees(rotationAngle))
    }
    .ignoresSafeArea()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(backgroundColor)
    .onAppear {
      withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
        rotationAngle = 360.0
      }
    }
  }
}

#Preview {
  LaunchingView()
}
