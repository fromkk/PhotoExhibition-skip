import SwiftUI

@Observable
final class MenuStore: Store {
  enum Action {}

  func send(_ action: Action) {}
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
      }
      .navigationBarTitle("Menu")
    }
  }
}

#Preview {
  MenuView(store: MenuStore())
}
