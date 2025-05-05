#if SKIP
  import SkipFirebaseAnalytics
#else
  import FirebaseAnalytics
#endif

public enum AnalyticsEvents: String, Sendable {
  case screenView = "screen_view"
  case signUp = "sign_up"
  case signIn = "sign_in"
  case profileEdit = "profile_edit"
  case report = "report"
  case contact = "contact"
  case exhibitionCreated = "exhibition_created"
  case exhibitionEdited = "exhibition_edited"
  case photoUploaded = "photo_uploaded"
  case exhibitionViewed = "exhibition_viewed"
  case photoViewed = "photo_viewed"
}

public protocol AnalyticsClient: Sendable {
  func send(_ event: AnalyticsEvents, parameters: [String: any Sendable]) async
  func analyticsScreen(name: String) async
}

public actor DefaultAnalyticsClient: AnalyticsClient {
  public init() {}

  public func send(_ event: AnalyticsEvents, parameters: [String: any Sendable]) async {
    Analytics.logEvent(event.rawValue, parameters: parameters)
  }

  public func analyticsScreen(name: String) async {
    Analytics.logEvent(
      AnalyticsEvents.screenView.rawValue,
      parameters: [
        "screen_name": name,
        "firebase_screen_class": "View",
      ])
  }
}
