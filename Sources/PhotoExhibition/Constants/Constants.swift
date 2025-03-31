import Foundation

enum Constants {
  static let termsOfServiceURL = URL(
    string: "https://www.kiyac.app/termsOfService/jqOQqqn2RkD1FktbfBrl")!
  static let privacyPolicyURL = URL(
    string: "https://www.kiyac.app/privacypolicy/XgDa0L1CzdrRy9Iii3M3")!
  static let hostingDomain: String = "exhivision.app"
  static let hashTag: String = "#exhivision_app"

  #if DEBUG
    static let adMobHomeFooterUnitID: String = "ca-app-pub-3940256099942544/2435281174"
  #elseif SKIP
    static let adMobHomeFooterUnitID: String = "ca-app-pub-4938162641824294/8567220300"
  #else
    static let adMobHomeFooterUnitID: String = "ca-app-pub-4938162641824294/4034601435"
  #endif
}
