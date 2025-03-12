import Foundation

protocol UserCacheClient: Sendable {
  func setUser(_ user: User) async
  func getUser(withUID uid: String) async -> User?
  func getAllUsers() async -> [User]
  func clearCache() async
}

actor DefaultUserCacheClient: UserCacheClient {
  static let shared = DefaultUserCacheClient()

  private var cachedUsers: [CachedUser] = []
  private let maxCacheSize: Int

  init(maxCacheSize: Int = 100) {
    self.maxCacheSize = maxCacheSize
  }

  func setUser(_ user: User) async {
    // Add or update user in cache
    addUserToCache(user)
  }

  func getUser(withUID uid: String) async -> User? {
    if let cachedUser = cachedUsers.first(where: { $0.user.uid == uid }) {
      // Update access time - this is critical for LRU to work correctly
      updateUserAccessTime(cachedUser.user)
      return cachedUser.user
    }

    return nil
  }

  func getAllUsers() async -> [User] {
    return cachedUsers.map { $0.user }
  }

  func clearCache() async {
    cachedUsers.removeAll()
  }

  private func addUserToCache(_ user: User) {
    // Check if user already exists in cache
    if let index = cachedUsers.firstIndex(where: { $0.user.uid == user.uid }) {
      // Update existing entry with current timestamp
      cachedUsers[index].lastAccessed = Date()
    } else {
      // Add new entry
      cachedUsers.append(CachedUser(user: user, lastAccessed: Date()))

      // If cache exceeds maximum size, remove oldest entries
      evictOldestIfNeeded()
    }
  }

  private func updateUserAccessTime(_ user: User) {
    if let index = cachedUsers.firstIndex(where: { $0.user.uid == user.uid }) {
      // Update the access time to current time
      cachedUsers[index].lastAccessed = Date()
    } else {
      // If user not in cache, add them
      addUserToCache(user)
    }
  }

  private func evictOldestIfNeeded() {
    if cachedUsers.count > maxCacheSize {
      // Sort by last accessed time (oldest first)
      cachedUsers.sort { $0.lastAccessed < $1.lastAccessed }

      // Remove oldest entries until we're back to max size
      cachedUsers = Array(cachedUsers.suffix(maxCacheSize))
    }
  }
}

// Helper struct to track when users were last accessed
private struct CachedUser {
  let user: User
  var lastAccessed: Date
}

// No need for Codable conformance since we're not persisting data
