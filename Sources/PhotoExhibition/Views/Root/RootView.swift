import SwiftUI

#if !SKIP
  import Launching
  import IntentHelper
#endif

struct RootView: View {
  @Bindable var store = RootStore()
  var body: some View {
    Group {
      if store.isLoading {
        #if !SKIP
          LaunchingView()
            .transition(
              .asymmetric(
                insertion: .identity,
                removal: .scale(scale: 2)
                  .combined(with: .opacity)
              )
            )
        #else
          VStack {
            Image("logo", bundle: .module)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.white)
        #endif
      } else {
        if store.isSignedIn {
          if let profileSetupStore = store.profileSetupStore {
            // Display profile setup screen
            NavigationStack {
              ProfileSetupView(store: profileSetupStore)
                .navigationTitle(Text("Profile Setup"))
                .navigationBarBackButtonHidden(true)
            }
          } else {
            // Display main screen (tab view)
            TabView(selection: $store.selectedTab) {
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
                .tag(Tab.exhibitions)
              }

              if let settingsStore = store.settingsStore {
                NavigationStack {
                  SettingsView(store: settingsStore)
                }
                .tabItem {
                  Label(
                    "Settings",
                    systemImage: SystemImageMapping.getIconName(from: "gear")
                  )
                }
                .tag(Tab.settings)
              }
            }
          }
        } else {
          AuthRootView(delegate: store)
        }
      }
    }
    .animation(.default, value: store.isLoading)
    .background(Color("background", bundle: .module))
    .task {
      store.send(.task)
    }
    .onOpenURL { url in
      store.send(.handleUniversalLink(url))
    }
    #if !SKIP
      .onReceive(
        NotificationCenter.default.publisher(for: .addExhibitionRequest),
        perform: { _ in
          store.send(.addExhibitionRequestReceived)
        }
      )
    #endif
  }
}

#Preview {
  RootView()
}
