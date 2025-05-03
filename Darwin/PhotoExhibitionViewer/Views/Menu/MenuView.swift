import SwiftUI
import Viewer

@Observable
final class MenuStore: Store {
  let deviceInfoClient: DeviceInfoClient
  init(deviceInfoClient: DeviceInfoClient = .liveValue) {
    self.deviceInfoClient = deviceInfoClient
  }

  enum Action {
    case contactButtonTapped
    case licenseButtonTapped
  }

  var contactStore: ContactStore?
  var licenseStore: LicenseListStore?

  func send(_ action: Action) {
    switch action {
    case .contactButtonTapped:
      contactStore = ContactStore(
        contactClient: DefaultContactClient()
      )
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
        Section {
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
            store.send(.contactButtonTapped)
          } label: {
            HStack {
              Text("Contact")
                .frame(maxWidth: .infinity, alignment: .leading)
              Image(systemName: "chevron.forward")
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
        } footer: {
          if let version = store.deviceInfoClient.appVersion(),
            let buildNumber = store.deviceInfoClient.buildNumber()
          {
            Text("\(version) (\(buildNumber))")
              .font(.footnote)
              .frame(maxWidth: .infinity, alignment: .center)
          }
        }
      }
      .navigationBarTitle("Menu")
      .navigationDestination(item: $store.licenseStore) { licenstListStore in
        LicenseListView(store: licenstListStore)
      }
      .navigationDestination(item: $store.contactStore) { contactStore in
        ContactView(store: contactStore)
      }
    }
  }
}

#Preview {
  MenuView(store: MenuStore())
}
