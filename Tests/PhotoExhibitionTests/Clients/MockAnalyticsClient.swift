@testable import PhotoExhibition

@MainActor
final class MockAnalyticsClient: AnalyticsClient {
  struct EventCall: Equatable {
    let event: AnalyticsEvents
    let parameters: [String: String]

    static func == (lhs: EventCall, rhs: EventCall) -> Bool {
      lhs.event == rhs.event && lhs.parameters == rhs.parameters
    }
  }

  struct ScreenCall: Equatable {
    let name: String
  }

  private(set) var eventCalls: [EventCall] = []
  private(set) var screenCalls: [ScreenCall] = []

  func send(_ event: AnalyticsEvents, parameters: [String: any Sendable]) async {
    let stringParameters = parameters.compactMapValues { $0 as? String }
    eventCalls.append(EventCall(event: event, parameters: stringParameters))
  }

  func analyticsScreen(name: String) async {
    screenCalls.append(ScreenCall(name: name))
  }
}
