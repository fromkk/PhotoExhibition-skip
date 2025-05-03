import Foundation

public struct DeviceInfoClient: Sendable {
  public var appVersion: @Sendable () -> String?
  public var buildNumber: @Sendable () -> String?

  public init(
    appVersion: @Sendable @escaping () -> String?, buildNumber: @Sendable @escaping () -> String?
  ) {
    self.appVersion = appVersion
    self.buildNumber = buildNumber
  }

  public static let liveValue: DeviceInfoClient = Self(
    appVersion: {
      return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    },
    buildNumber: {
      return (Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
    }
  )
}
