import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@MainActor
protocol ProfileSetupStoreDelegate: AnyObject {
  func didCompleteProfileSetup()
}

@Observable final class ProfileSetupStore: Store {
  enum Action {
    case saveButtonTapped
    case dismissError
  }

  let member: Member
  var name: String = ""
  weak var delegate: (any ProfileSetupStoreDelegate)?

  // State management
  var isLoading: Bool = false
  var error: (any Error)?
  var isErrorAlertPresented: Bool = false

  private let memberUpdateClient: any MemberUpdateClient

  init(
    member: Member,
    memberUpdateClient: MemberUpdateClient = DefaultMemberUpdateClient()
  ) {
    self.member = member
    self.memberUpdateClient = memberUpdateClient

    // Set initial value if existing name is available
    if let existingName = member.name {
      self.name = existingName
    }
  }

  func send(_ action: Action) {
    switch action {
    case .saveButtonTapped:
      isLoading = true
      error = nil
      isErrorAlertPresented = false

      Task {
        do {
          let updatedMember = try await memberUpdateClient.updateName(
            memberID: member.id, name: name)
          print("Profile update success: \(updatedMember.id)")
          delegate?.didCompleteProfileSetup()
        } catch {
          self.error = error
          self.isErrorAlertPresented = true
          print("Profile update error: \(error.localizedDescription)")
        }

        isLoading = false
      }

    case .dismissError:
      isErrorAlertPresented = false
    }
  }
}

struct ProfileSetupView: View {
  @Bindable var store: ProfileSetupStore

  var body: some View {
    VStack(spacing: 32) {
      Text("Set Up Profile")
        .font(.title)
        .padding(.bottom, 8)

      Text("Please set a username to continue using the app")
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      TextField("Username", text: $store.name)
        .textFieldStyle(.roundedBorder)
        .padding(.horizontal)

      Button {
        store.send(.saveButtonTapped)
      } label: {
        if store.isLoading {
          ProgressView()
        } else {
          Text("Save")
            .primaryButtonStyle()
        }
      }
      .disabled(store.name.isEmpty || store.isLoading)
    }
    .padding()
    .alert(
      "Error",
      isPresented: $store.isErrorAlertPresented,
      actions: {
        Button {
          store.send(.dismissError)
        } label: {
          Text("OK")
        }
      },
      message: {
        Text(store.error?.localizedDescription ?? "An unknown error occurred")
      }
    )
  }
}

#Preview {
  let previewMember = Member(
    id: "preview-id",
    name: nil,
    icon: nil,
    createdAt: Date(),
    updatedAt: Date()
  )

  return ProfileSetupView(store: ProfileSetupStore(member: previewMember))
}
