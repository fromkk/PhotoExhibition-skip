import SwiftUI

@Observable @MainActor public final class LicenseListStore: Store, @preconcurrency Hashable {
  public init() {}

  var licenses: [License] = []
  var isShowLicenseDetail: Bool = false
  var detailStore: LicenseDetailStore?

  public enum Action {
    case task
    case licenseTapped(License)
  }

  public func send(_ action: Action) {
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

  public var hashValue: Int { licenses.hashValue }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(hashValue)
  }

  public static func == (lhs: LicenseListStore, rhs: LicenseListStore) -> Bool {
    lhs.licenses == rhs.licenses
  }
}

public struct LicenseListView: View {
  @Bindable var store: LicenseListStore
  public init(store: LicenseListStore) {
    self.store = store
  }

  public var body: some View {
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
    .navigationDestination(
      isPresented: Binding(
        get: {
          store.detailStore != nil
        },
        set: {
          if !$0 {
            store.detailStore = nil
          }
        }
      )
    ) {
      if let store = store.detailStore {
        LicenseDetailView(store: store)
      }
    }
  }
}
