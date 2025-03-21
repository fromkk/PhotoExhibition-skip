import SwiftUI

struct RootView: View {
  @Bindable var store = AppStore()
  var body: some View {
    Group {
      if store.isSignedIn {
        if store.isProfileSetupShown, let profileSetupStore = store.profileSetupStore {
          // Display profile setup screen
          NavigationStack {
            ProfileSetupView(store: profileSetupStore)
              .navigationTitle("Profile Setup")
              .navigationBarBackButtonHidden(true)
          }
        } else {
          // Display main screen (tab view)
          TabView {
            if let exhibitionsStore = store.exhibitionsStore {
              NavigationStack {
                ExhibitionsView(store: exhibitionsStore)
              }
              .tabItem {
                #if SKIP
                  Image("photo", bundle: .module)
                  Text("Exhibitions")
                #else
                  Label("Exhibitions", systemImage: "photo")
                #endif
              }
            }

            if let settingsStore = store.settingsStore {
              NavigationStack {
                SettingsView(store: settingsStore)
              }
              .tabItem {
                Label("Settings", systemImage: SystemImageMapping.getIconName(from: "gear"))
              }
            }
          }
        }
      } else {
        AuthRootView(delegate: store)
      }
    }
    .background(Color("background", bundle: .module))
    .task {
      store.send(.task)
    }
  }
}

#Preview {
  RootView()
}
