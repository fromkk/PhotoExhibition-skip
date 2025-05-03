import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled
  func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .fontWeight(.semibold)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(isEnabled ? Color.accentColor : Color.gray)
      .foregroundStyle(Color.white)
      .clipShape(Capsule())
  }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
  static var primaryButtonStyle: Self { Self() }
}

struct SecondaryButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled
  func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .fontWeight(.semibold)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .foregroundStyle(isEnabled ? Color.accentColor : Color.gray)
      .clipShape(Capsule())
      .overlay {
        Capsule()
          .inset(by: 0.5)
          .stroke(
            isEnabled ? Color.accentColor : Color.gray,
            style: StrokeStyle(lineWidth: 1.0)
          )
      }
  }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
  static var secondaryButtonStyle: Self { Self() }
}
