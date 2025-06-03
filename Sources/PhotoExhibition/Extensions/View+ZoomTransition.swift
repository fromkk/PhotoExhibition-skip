#if !SKIP
  import SwiftUI

  /// for iOS 18
  extension View {
    public func zoomTransition(_ id: String?, in namespace: Namespace.ID) -> some View {
      return
        self
        .iOS18_transitionStyleZoom(id, in: namespace)
        .iOS18_matchedTransitionSource(id, in: namespace)
    }

    public func iOS18_transitionStyleZoom(_ id: String?, in namespace: Namespace.ID) -> some View {
      if #available(iOS 18, visionOS 2, macOS 15, *) {
        return navigationTransition(.zoom(sourceID: id, in: namespace))
      } else {
        return self
      }
    }

    public func iOS18_matchedTransitionSource(_ id: String?, in namespace: Namespace.ID)
      -> some View
    {
      if #available(iOS 18, visionOS 2, macOS 15, *) {
        return matchedTransitionSource(id: id, in: namespace)
      } else {
        return self
      }
    }
  }

#endif
