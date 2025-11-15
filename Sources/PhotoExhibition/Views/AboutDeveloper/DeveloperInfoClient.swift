import Foundation

struct DeveloperInfoClient: Sendable {
    var developerInfo: @Sendable () -> DeveloperInfo?
}

extension DeveloperInfoClient {
    static let liveValue: Self = {
        return Self(
            developerInfo: {
              DeveloperInfo(
                title: String(localized: "About Developer Title", table: "AboutDeveloper", bundle: .module),
                description: String(localized: "About Developer Description", table: "AboutDeveloper", bundle: .module),
                iconUrl: URL(string: "https://fromkk.me/assets/kakkun-1db32db2.png")!,
                xUrl: URL(string: "https://x.com/fromkk")!,
                websiteUrl: URL(string: "https://fromkk.me/?from=exhivision"),
                termsOfRulesUrl: Constants.termsOfServiceURL,
                privacyPolicyUrl: Constants.privacyPolicyURL,
                apps: [
                  .init(name: "# Type",
                        description: String(localized: "Type Description", table: "AboutDeveloper", bundle: .module),
                        iconUrl: URL(string: "https://fromkk.me/assets/type-bdab56aa.png")!,
                        appStoreUrl: URL(string: "https://apps.apple.com/app/id1214613873")!,
                        appStoreId: "1214613873"),
                  .init(name: "Quiz Match",
                        description: String(localized: "Quiz Match Description", table: "AboutDeveloper", bundle: .module),
                        iconUrl: URL(string: "https://fromkk.me/assets/quiz_match-23d2f8a6.png")!,
                        appStoreUrl: URL(string: "https://apps.apple.com/app/id6738331234")!,
                        appStoreId: "6738331234"),
                ],
                supportProductId: "me.fromkk.exhivision.support1"
              )
            }
        )
    }()
}
