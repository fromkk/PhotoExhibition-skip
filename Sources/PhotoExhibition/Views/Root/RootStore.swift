import CryptoKit
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

#if !SKIP
  import AuthenticationServices
#endif

@Observable
final class RootStore: Store, AuthStoreDelegate, SettingsStoreDelegate, ProfileSetupStoreDelegate {
  private let currentUserClient: CurrentUserClient
  private let membersClient: MembersClient
  #if !SKIP
    private let authClient: AuthClient
    private var currentNonce: String?
  #endif

  var error: Error?

  #if !SKIP
    init(
      currentUserClient: CurrentUserClient = DefaultCurrentUserClient(),
      membersClient: MembersClient = DefaultMembersClient(),
      authClient: AuthClient = DefaultAuthClient()
    ) {
      self.currentUserClient = currentUserClient
      self.membersClient = membersClient
      self.authClient = authClient
    }
  #else
    init(
      currentUserClient: CurrentUserClient = DefaultCurrentUserClient(),
      membersClient: MembersClient = DefaultMembersClient()
    ) {
      self.currentUserClient = currentUserClient
      self.membersClient = membersClient
    }
  #endif

  enum Action: Sendable {
    case task
    case signInButtonTapped
    case signUpButtonTapped
    #if !SKIP
      case signInWithAppleCompleted(Result<ASAuthorization, Error>)
    #endif
  }

  private(set) var isSignedIn: Bool = false {
    didSet {
      if isSignedIn {
        exhibitionsStore = ExhibitionsStore()
        settingsStore = SettingsStore()
        settingsStore?.delegate = self
      } else {
        exhibitionsStore = nil
        settingsStore = nil
        profileSetupStore = nil
      }
    }
  }
  // Updated flags for signIn and signUp screen display
  var isSignInScreenShown: Bool = false {
    didSet {
      if isSignInScreenShown {
        authStore = AuthStore(authMode: .signIn)
        authStore?.delegate = self
      } else {
        authStore = nil
      }
    }
  }
  var isSignUpScreenShown: Bool = false {
    didSet {
      if isSignUpScreenShown {
        authStore = AuthStore(authMode: .signUp)
        authStore?.delegate = self
      } else {
        authStore = nil
      }
    }
  }

  var isProfileSetupShown: Bool = false

  private(set) var authStore: AuthStore?
  private(set) var exhibitionsStore: ExhibitionsStore?
  private(set) var settingsStore: SettingsStore?
  private(set) var profileSetupStore: ProfileSetupStore?

  #if !SKIP
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }

    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
  #endif

  func send(_ action: Action) {
    switch action {
    case .task:
      if let currentUser = currentUserClient.currentUser() {
        // ユーザーがログインしているが、Memberを取得する必要がある場合
        Task {
          do {
            let members = try await membersClient.fetch([currentUser.uid])
            if let member = members.first {
              isSignedIn = true

              // メンバー名が設定されていない場合はプロフィール設定画面を表示
              if member.name == nil {
                showProfileSetup(for: member)
              }
            } else {
              // メンバー情報が取得できなかった場合
              isSignedIn = false
            }
          } catch {
            print("Failed to fetch member: \(error.localizedDescription)")
            isSignedIn = false
          }
        }
      } else {
        isSignedIn = false
      }
    case .signInButtonTapped:
      isSignInScreenShown = true
      return
    case .signUpButtonTapped:
      isSignUpScreenShown = true
      return
    #if !SKIP
      case let .signInWithAppleCompleted(result):
        Task {
          do {
            let authorization = try result.get()
            guard let nonce = currentNonce else {
              throw AuthClientError.invalidCredential
            }
            let member = try await authClient.signInWithApple(
              authorization: authorization, nonce: nonce)
            await MainActor.run {
              didSignInSuccessfully(with: member)
            }
          } catch {
            self.error = error
          }
        }
    #endif
    }
  }

  // MARK: - AuthStoreDelegate

  func didSignInSuccessfully(with member: Member) {
    isSignInScreenShown = false
    isSignUpScreenShown = false
    isSignedIn = true

    // Show profile setup screen if member name is not set
    if member.name == nil {
      showProfileSetup(for: member)
    }
  }

  // MARK: - SettingsStoreDelegate

  func logoutCompleted() {
    isSignedIn = false
  }

  func deleteAccountCompleted() {
    isSignedIn = false
  }

  // MARK: - ProfileSetupStoreDelegate

  func didCompleteProfileSetup() {
    isProfileSetupShown = false
    profileSetupStore = nil
  }

  // MARK: - Helper Methods

  private func showProfileSetup(for member: Member) {
    let store = ProfileSetupStore(member: member)
    store.delegate = self
    profileSetupStore = store
    isProfileSetupShown = true
  }
}

#if !SKIP
  extension RootStore {
    func prepareSignInWithApple() -> String {
      let nonce = randomNonceString()
      currentNonce = nonce
      return sha256(nonce)
    }
  }
#endif
