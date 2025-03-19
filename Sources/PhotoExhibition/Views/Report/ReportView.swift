import SwiftUI

struct ReportView: View {
  @Bindable var store: ReportStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextEditor(text: $store.reason)
            .frame(minHeight: 200)
            .onChange(of: store.reason) { _, newValue in
              store.send(.reasonChanged(newValue))
            }
        } header: {
          Text("Reason")
        } footer: {
          Text("Please provide a reason for reporting this content.")
        }
      }
      .navigationTitle("Report")
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
          .disabled(store.reason.isEmpty || store.isLoading)
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
  ReportView(store: ReportStore(type: .exhibition, id: "preview"))
}
