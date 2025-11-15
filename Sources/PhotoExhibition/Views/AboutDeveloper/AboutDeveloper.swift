import Foundation
import OSLog

struct DeveloperInfo: Hashable, Decodable {
    let title: String
    let description: String
    let iconUrl: URL
    let xUrl: URL?
    let websiteUrl: URL?
    let termsOfRulesUrl: URL?
    let privacyPolicyUrl: URL?
    let apps: [App]
    let supportProductId: String
    struct App: Hashable, Decodable {
        let name: String
        let description: String
        let iconUrl: URL
        let appStoreUrl: URL
        let appStoreId: String
    }
}
