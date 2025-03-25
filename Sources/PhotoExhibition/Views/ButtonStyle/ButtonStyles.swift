import SwiftUI

extension View {
  func primaryButtonStyle() -> some View {
    self
      .fontWeight(.semibold)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color.accentColor)
      .foregroundStyle(Color.white)
      .clipShape(Capsule())
  }

  func disabledButtonStyle() -> some View {
    self
      .fontWeight(.semibold)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color.gray)
      .foregroundStyle(Color.white)
      .clipShape(Capsule())
  }

  func secondaryButtonStyle() -> some View {
    self
      .fontWeight(.semibold)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .foregroundStyle(Color.accentColor)
      .clipShape(Capsule())
      .overlay {
        Capsule()
          .inset(by: 0.5)
          .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.0))
      }
  }
}
