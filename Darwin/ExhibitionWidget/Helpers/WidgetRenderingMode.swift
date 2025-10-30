import SwiftUI
import WidgetKit

public enum WidgetRenderingMode {
  case fullColor
  case accented
  case desaturated
  case accentedDesaturated
}

extension Image {
  @ViewBuilder
  public func iOS18_widgetAccentedRenderingMode(_ renderingMode: WidgetRenderingMode) -> some View {
    if #available(iOS 18.0, *) {
      switch renderingMode {
      case .fullColor:
        self
          .widgetAccentedRenderingMode(.fullColor)
      case .accented:
        self
          .widgetAccentedRenderingMode(.accented)
      case .desaturated:
        self
          .widgetAccentedRenderingMode(.desaturated)
      case .accentedDesaturated:
        self
          .widgetAccentedRenderingMode(.accentedDesaturated)
      }
    }
    else {
      self
    }
  }
}
