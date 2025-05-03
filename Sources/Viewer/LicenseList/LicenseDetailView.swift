import SwiftUI

@Observable public final class LicenseDetailStore: Store {
  public init(license: License) {
    self.license = license
  }

  let license: License
  public enum Action {}
  public func send(_ action: Action) {
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
