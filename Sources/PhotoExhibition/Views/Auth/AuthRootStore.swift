import SwiftUI

#if canImport(Observation)
  import Observation
#endif

#if !SKIP
  import AuthenticationServices
  import CryptoKit
#endif

@MainActor
protocol AuthRootStoreDelegate: AnyObject {
  func didSignInSuccessfully(with member: Member)
}

@Observable
final class AuthRootStore: Store {
  private let currentUserClient: any CurrentUserClient
  private let membersClient: any MembersClient
  private let analyticsClient: any AnalyticsClient
  #if !SKIP
    private let authClient: AuthClient
    private var currentNonce: String?
  #endif

  weak var delegate: (any AuthRootStoreDelegate)?
  var error: Error?

  #if !SKIP
    init(
      currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
      membersClient: any MembersClient = DefaultMembersClient(),
      authClient: any AuthClient = DefaultAuthClient(),
      analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
    ) {
      self.currentUserClient = currentUserClient
      self.membersClient = membersClient
      self.authClient = authClient
      self.analyticsClient = analyticsClient
    }
  #else
    init(
      currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
      membersClient: any MembersClient = DefaultMembersClient(),
      analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
    ) {
      self.currentUserClient = currentUserClient
      self.membersClient = membersClient
      self.analyticsClient = analyticsClient
    }
  #endif

  enum Action: Sendable {
    case task
    case signInButtonTapped
    case signUpButtonTapped
    #if !SKIP
      case signInWithAppleCompleted(Result<ASAuthorization, Error>)
    #endif
    case didSignInSuccessfully(Member)
  }

  var showSignIn: Bool = false {
    didSet {
      if showSignIn {
        authStore = AuthStore(authMode: .signIn)
        authStore?.delegate = self
      } else {
        authStore = nil
      }
    }
  }
  var showSignUp: Bool = false {
    didSet {
      if showSignUp {
        authStore = AuthStore(authMode: .signUp)
        authStore?.delegate = self
      } else {
        authStore = nil
      }
    }
  }

  private(set) var authStore: AuthStore?

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
      Task {
        await analyticsClient.analyticsScreen(name: "AuthRootView")
      }
    case .signInButtonTapped:
      authStore = AuthStore(authMode: .signIn)
      authStore?.delegate = self
      showSignIn = true
    case .signUpButtonTapped:
      authStore = AuthStore(authMode: .signUp)
      authStore?.delegate = self
      showSignUp = true
    #if !SKIP
      case .signInWithAppleCompleted(let result):
        switch result {
        case .success(let authorization):
          guard
            let nonce = currentNonce
          else {
            error = NSError(
              domain: "AuthRootStore", code: -1,
              userInfo: [NSLocalizedDescriptionKey: "Invalid credential"])
            return
          }

          Task {
            do {
              let member = try await authClient.signInWithApple(
                authorization: authorization, nonce: nonce)
              delegate?.didSignInSuccessfully(with: member)
            } catch {
              self.error = error
            }
          }
        case .failure(let error):
          self.error = error
        }
    #endif
    case .didSignInSuccessfully(let member):
      showSignIn = false
      showSignUp = false
      delegate?.didSignInSuccessfully(with: member)
    }
  }
}

extension AuthRootStore: AuthStoreDelegate {
  func didSignInSuccessfully(with member: Member) {
    send(.didSignInSuccessfully(member))
  }
}

#if !SKIP
  extension AuthRootStore {
    func prepareSignInWithApple() -> String {
      let nonce = randomNonceString()
      currentNonce = nonce
      return sha256(nonce)
    }
  }
#endif
