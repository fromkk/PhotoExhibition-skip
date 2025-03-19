import SwiftUI

struct ContactView: View {
  @Bindable var store: ContactStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Title", text: $store.title)
            .onChange(of: store.title) { _, newValue in
              store.send(.titleChanged(newValue))
            }
        }

        Section {
          TextEditor(text: $store.content)
            .frame(minHeight: 200)
            .onChange(of: store.content) { _, newValue in
              store.send(.contentChanged(newValue))
            }
        }
      }
      .navigationTitle("Contact")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            store.send(.dismissButtonTapped)
          }
          .disabled(store.isLoading)
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Send") {
            store.send(.sendButtonTapped)
          }
          .disabled(store.title.isEmpty || store.content.isEmpty || store.isLoading)
        }
      }
      .alert("Error", isPresented: $store.isErrorAlertPresented) {
        Button("OK") {}
      } message: {
        if let errorMessage = store.error?.localizedDescription {
          Text(errorMessage)
        }
      }
      .onChange(of: store.shouldDismiss) { _, shouldDismiss in
        if shouldDismiss {
          dismiss()
        }
      }
    }
  }
}

#Preview {
  ContactView(store: ContactStore())
}
