#if !SKIP
  import SwiftUI

  @Observable final class LicenseListStore: Store {
    var licenses: [License] = []
    var isShowLicenseDetail: Bool = false
    var detailStore: LicenseDetailStore?

    enum Action {
      case task
      case licenseTapped(License)
    }

    func send(_ action: Action) {
      switch action {
      case .task:
        self.licenses = LicensesPlugin.licenses.compactMap {
          if let licenseText = $0.licenseText {
            return License(id: $0.id, name: $0.name, description: licenseText)
          } else {
            return nil
          }
        }
      case let .licenseTapped(license):
        detailStore = LicenseDetailStore(license: license)
        isShowLicenseDetail = true
      }
    }
  }

  struct LicenseListView: View {
    @Bindable var store: LicenseListStore

    var body: some View {
      List(store.licenses) { license in
        Button {
          store.send(.licenseTapped(license))
        } label: {
          Text(license.name)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
      }
      .task {
        store.send(.task)
      }
      .navigationTitle(Text("Licenses"))
      .navigationDestination(isPresented: $store.isShowLicenseDetail) {
        if let store = store.detailStore {
          LicenseDetailView(store: store)
        }
      }
    }
  }
#endif
