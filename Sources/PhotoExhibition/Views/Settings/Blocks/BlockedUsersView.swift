import Foundation
import OSLog
import PhotoExhibitionModel
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BlockedUsersStore")

@Observable
final class BlockedUsersStore: Store {
  enum Action: Sendable {
    case task
    case refreshed
    case unblockButtonTapped(String)
    case unblockUserCompleted(String)
  }

  var blockedUsers: [Member] = []
  var isLoading: Bool = false
  var showErrorAlert: Bool = false
  var error: Error? = nil

  private let blockClient: any BlockClient
  private let currentUserClient: any CurrentUserClient
  private let membersClient: any MembersClient

  init(
    blockClient: any BlockClient = DefaultBlockClient.shared,
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    membersClient: any MembersClient = DefaultMembersClient()
  ) {
    self.blockClient = blockClient
    self.currentUserClient = currentUserClient
    self.membersClient = membersClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      loadBlockedUsers()
    case .refreshed:
      loadBlockedUsers()
    case .unblockButtonTapped(let userId):
      unblockUser(userId)
    case .unblockUserCompleted(let userId):
      // Remove the unblocked user from the list
      blockedUsers.removeAll { $0.id == userId }
    }
  }

  private func loadBlockedUsers() {
    guard let currentUser = currentUserClient.currentUser() else { return }

    isLoading = true
    blockedUsers = []

    Task {
      do {
        // Get the list of blocked user IDs
        let blockedUserIds = try await blockClient.fetchBlockedUserIds(
          currentUserId: currentUser.uid)

        if blockedUserIds.isEmpty {
          isLoading = false
          return
        }

        // Fetch user information
        let members = try await membersClient.fetch(blockedUserIds)

        await MainActor.run {
          self.blockedUsers = members
          self.isLoading = false
        }
      } catch {
        logger.error("Failed to load blocked users: \(error.localizedDescription)")
        await MainActor.run {
          self.error = error
          self.showErrorAlert = true
          self.isLoading = false
        }
      }
    }
  }

  private func unblockUser(_ userId: String) {
    guard let currentUser = currentUserClient.currentUser() else { return }

    Task {
      do {
        try await blockClient.unblockUser(currentUserId: currentUser.uid, blockUserId: userId)
        logger.info("Unblocked user: \(userId)")

        await MainActor.run {
          send(.unblockUserCompleted(userId))
        }
      } catch {
        logger.error("Failed to unblock user: \(error.localizedDescription)")
        await MainActor.run {
          self.error = error
          self.showErrorAlert = true
        }
      }
    }
  }
}

struct BlockedUsersView: View {
  @Bindable var store: BlockedUsersStore

  var body: some View {
    List {
      if store.isLoading {
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        .padding()
      } else if store.blockedUsers.isEmpty {
        Text("No blocked users")
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding()
      } else {
        ForEach(store.blockedUsers) { member in
          HStack {
            // Display user information using MemberRowView
            MemberRowView(userId: member.id)
              .frame(maxWidth: .infinity, alignment: .leading)

            // Unblock button
            Button {
              store.send(.unblockButtonTapped(member.id))
            } label: {
              Text("Unblock")
                .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
          }
          .padding(8)
        }
      }
    }
    .navigationTitle("Blocked Users")
    .onAppear {
      store.send(.task)
    }
    .refreshable {
      store.send(.refreshed)
    }
    .alert(
      "Error",
      isPresented: Binding(
        get: { store.error != nil },
        set: { if !$0 { store.error = nil } }
      )
    ) {
      Button("OK") {
        store.error = nil
      }
    } message: {
      if let error = store.error {
        Text(error.localizedDescription)
      }
    }
  }
}
