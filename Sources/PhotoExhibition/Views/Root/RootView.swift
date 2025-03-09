import SwiftUI

struct RootView: View {
  @State var store = RootStore()
  var body: some View {
    Group {
      if store.isSignedIn {
        Text("Signed in")
      } else {
        Text("Not signed in")
      }
    }
    .task {
      store.send(.task)
    }
  }
}
