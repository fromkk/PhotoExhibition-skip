#if !SKIP
  import SwiftUI

  @Observable final class LicenseDetailStore: Store {
    init(license: License) {
      self.license = license
    }

    let license: License
    enum Action {}
    func send(_ action: Action) {
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

#endif
