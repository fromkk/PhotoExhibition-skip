#if SKIP
  import SkipFirebaseAnalytics
#else
  import FirebaseAnalytics
#endif

/*
 - 画面表示
 */
enum AnalyticsEvents: String, Sendable {
  case screenView = "screen_View"
}

protocol AnalyticsClient: Sendable {
  func analyticsScreen(name: String) async
}

actor DefaultAnalyticsClient: AnalyticsClient {
  func analyticsScreen(name: String) async {
    Analytics.logEvent(
      AnalyticsEvents.screenView.rawValue,
      parameters: [
        "screen_name": name
      ])
  }
}
