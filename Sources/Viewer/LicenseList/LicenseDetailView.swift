import SwiftUI

@Observable @MainActor public final class LicenseDetailStore: Store, @preconcurrency Hashable {
  public init(license: License) {
    self.license = license
  }

  let license: License
  public enum Action {}
  public func send(_ action: Action) {}

  public var hashValue: Int { license.hashValue }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(hashValue)
  }
  public static func == (lhs: LicenseDetailStore, rhs: LicenseDetailStore) -> Bool {
    lhs.license == rhs.license
  }
}

struct LicenseDetailView: View {
  @Bindable var store: LicenseDetailStore

  var body: some View {
    ScrollView {
      Text(store.license.description)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
    .navigationTitle(Text(store.license.name))
  }
}
