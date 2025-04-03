import Foundation

protocol DeviceInfo: Sendable {
  var appVersion: String? { get }
  var buildNumber: Int? { get }
}

struct DefaultDeviceInfo: DeviceInfo {
  var appVersion: String? {
    #if !os(Android)
      return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    #else
      let context = ProcessInfo.processInfo.androidContext
      let packageManager = context.getPackageManager()
      let packageInfo = packageManager.getPackageInfo(
        context.getPackageName(), android.content.pm.PackageManager.GET_META_DATA)
      return packageInfo.versionName
    #endif
  }

  var buildNumber: Int? {
    #if !os(Android)
      return (Bundle.main.infoDictionary?["CFBundleVersion"] as? String).flatMap(Int.init)
    #else
      let context = ProcessInfo.processInfo.androidContext
      let packageManager = context.getPackageManager()
      let info = context.packageManager.getPackageInfo(context.getPackageName(), 0)
      return info.versionCode
    #endif
  }
}
