import SwiftUI
import Viewer

@Observable
final class MenuStore: Store {
  enum Action {
    case licenseButtonTapped
  }

  var licenseStore: LicenseListStore?

  func send(_ action: Action) {
    switch action {
    case .licenseButtonTapped:
      licenseStore = LicenseListStore()
    }
  }
}

struct MenuView: View {
  @Bindable var store: MenuStore

  @Environment(\.openURL) var openURL

  var body: some View {
    NavigationStack {
      List {
        Button {
          openURL(Constants.termsOfServiceURL)
        } label: {
          HStack {
            Text("Terms of Service")
              .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "rectangle.on.rectangle")
          }
        }

        Button {
          openURL(Constants.privacyPolicyURL)
        } label: {
          HStack {
            Text("Privacy Policy")
              .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "rectangle.on.rectangle")
          }
        }

        Button {
          store.send(.licenseButtonTapped)
        } label: {
          HStack {
            Text("Licenses")
              .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.forward")
          }
        }
        .navigationDestination(item: $store.licenseStore) { licenstListStore in
          LicenseListView(store: licenstListStore)
        }
      }
      .navigationBarTitle("Menu")
    }
  }
}

#Preview {
  MenuView(store: MenuStore())
}
