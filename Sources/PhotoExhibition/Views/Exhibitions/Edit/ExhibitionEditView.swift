import OSLog
import SkipKit
import SwiftUI

#if canImport(Observation)
  import Observation
#endif
#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier!, category: "ExhibitionsStore")

// 展示会の作成・編集用のStore
@Observable
final class ExhibitionEditStore: Store {
  enum Mode: Equatable {
    case create
    case edit(Exhibition)
  }

  enum Action {
    case save
    case cancel
    case changeCoverImageButtonTapped
    case updateName(String)
    case updateDescription(String)
    case updateFrom(Date)
    case updateTo(Date)
    case updateCoverImage(URL?)
  }

  var name: String = ""
  var description: String = ""
  var from: Date = Date()
  var to: Date = Date().addingTimeInterval(60 * 60 * 24 * 7)  // 1週間後

  var isLoading: Bool = false
  var error: ExhibitionEditError? = nil
  var showError: Bool = false
  var shouldDismiss: Bool = false

  var imagePickerPresented: Bool = false
  var pickedImageURL: URL?
  var coverImageURL: URL?

  private let mode: Mode
  private let currentUserClient: CurrentUserClient
  private let exhibitionsClient: ExhibitionsClient
  private let storageClient: StorageClient

  init(
    mode: Mode,
    currentUserClient: CurrentUserClient = DefaultCurrentUserClient(),
    exhibitionsClient: ExhibitionsClient = DefaultExhibitionsClient(),
    storageClient: StorageClient = DefaultStorageClient()
  ) {
    self.mode = mode
    self.currentUserClient = currentUserClient
    self.exhibitionsClient = exhibitionsClient
    self.storageClient = storageClient

    if case .edit(let exhibition) = mode {
      self.name = exhibition.name
      self.description = exhibition.description ?? ""
      self.from = exhibition.from
      self.to = exhibition.to

      // カバー画像のパスがある場合は、StorageClientからURLを取得する
      if let coverImagePath = exhibition.coverImagePath {
        Task {
          do {
            let url = try await storageClient.url(coverImagePath)
            self.coverImageURL = url
          } catch {
            logger.error("Failed to get download URL: \(error.localizedDescription)")
          }
        }
      }
    }
  }

  func send(_ action: Action) {
    logger.info("action \(String(describing: action))")
    switch action {
    case .save:
      Task {
        do {
          guard !name.isEmpty else {
            error = .emptyName
            showError = true
            return
          }

          guard let user = currentUserClient.currentUser() else {
            error = .userNotLoggedIn
            showError = true
            return
          }

          isLoading = true
          try await saveExhibition(user: user)
          shouldDismiss = true
        } catch {
          self.error = .saveFailed(error.localizedDescription)
          showError = true
        }
        isLoading = false
      }
    case .cancel:
      shouldDismiss = true
    case .updateName(let newName):
      name = newName
    case .updateDescription(let newDescription):
      description = newDescription
    case .updateFrom(let newFrom):
      from = newFrom
      if to < newFrom {
        to = newFrom.addingTimeInterval(60 * 60 * 24)  // 1日後
      }
    case .updateTo(let newTo):
      to = newTo
    case .updateCoverImage(let url):
      coverImageURL = url
    case .changeCoverImageButtonTapped:
      imagePickerPresented = true
    }
  }

  private func saveExhibition(user: User) async throws {
    var coverImagePath: String?

    // カバー画像をStorageにアップロードする
    if let pickedImageURL = pickedImageURL {
      let fileName =
        UUID().uuidString + "."
        + (pickedImageURL.pathExtension.isEmpty ? "jpt" : pickedImageURL.pathExtension)
      let storagePath = "members/\(user.uid)/\(fileName)"

      // 画像をアップロードしてURLを取得
      coverImageURL = try await storageClient.upload(
        from: pickedImageURL,
        to: storagePath
      )

      coverImagePath = storagePath
    }

    var data: [String: any Sendable] = [
      "name": name,
      "description": description,
      "from": Timestamp(date: from),
      "to": Timestamp(date: to),
      "organizer": user.uid,
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    if let coverImagePath = coverImagePath {
      data["coverImagePath"] = coverImagePath
    }

    switch mode {
    case .create:
      data["createdAt"] = FieldValue.serverTimestamp()
      _ = try await exhibitionsClient.create(data: data)
    case .edit(let exhibition):
      try await exhibitionsClient.update(id: exhibition.id, data: data)
    }
  }
}

enum ExhibitionEditError: Error, LocalizedError {
  case emptyName
  case userNotLoggedIn
  case saveFailed(String)

  var errorDescription: String? {
    switch self {
    case .emptyName:
      return "Please enter exhibition name"
    case .userNotLoggedIn:
      return "Please login"
    case .saveFailed(let message):
      return "Failed to save: \(message)"
    }
  }
}

@MainActor
protocol ExhibitionEditStoreDelegate: AnyObject {
  func didSaveExhibition()
  func didCancelExhibition()
}

struct ExhibitionEditView: View {
  @Bindable var store: ExhibitionEditStore
  @Environment(\.dismiss) private var dismiss

  init(store: ExhibitionEditStore) {
    self.store = store
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Basic Information") {
          VStack(alignment: .leading) {
            AsyncImage(
              url: store.coverImageURL ?? store.pickedImageURL,
              content: { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(maxWidth: .infinity)
              },
              placeholder: {
                ProgressView()
                  .frame(maxWidth: .infinity)
              }
            )

            Button {
              store.send(.changeCoverImageButtonTapped)
            } label: {
              Text("Select Cover Image")
            }
          }
          .withMediaPicker(
            type: MediaPickerType.library,
            isPresented: $store.imagePickerPresented,
            selectedImageURL: $store.pickedImageURL
          )

          TextField("Exhibition Name", text: $store.name)
            .onChange(of: store.name) { _, newValue in
              store.send(.updateName(newValue))
            }

          TextField("Description", text: $store.description)
            .onChange(of: store.description) { _, newValue in
              store.send(.updateDescription(newValue))
            }
            .lineLimit(5)
            .multilineTextAlignment(.leading)
        }

        Section("Period") {
          DatePicker(
            "Start Date", selection: $store.from, displayedComponents: [.date]
          )
          .onChange(of: store.from) { _, newValue in
            store.send(.updateFrom(newValue))
          }
          .datePickerStyle(.compact)

          DatePicker(
            "End Date", selection: $store.to, displayedComponents: [.date]
          )
          .onChange(of: store.to) { _, newValue in
            store.send(.updateTo(newValue))
          }
          .datePickerStyle(.compact)
        }
      }
      .navigationTitle(store.name.isEmpty ? "New Exhibition" : store.name)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            store.send(.cancel)
          }
          .disabled(store.isLoading)
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            store.send(.save)
          }
          .disabled(store.isLoading)
        }
      }
      .alert("Error", isPresented: $store.showError) {
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
  ExhibitionEditView(store: ExhibitionEditStore(mode: .create))
}
