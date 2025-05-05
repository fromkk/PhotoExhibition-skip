import Foundation

public protocol MemberCacheClient: Sendable {
  func setMember(_ member: Member) async
  func getMember(withID id: String) async -> Member?
  func getAllMembers() async -> [Member]
  func clearCache() async
}

public actor DefaultMemberCacheClient: MemberCacheClient {
  public static let shared = DefaultMemberCacheClient()

  private var cachedMembers: [CachedMember] = []
  private let maxCacheSize: Int

  public init(maxCacheSize: Int = 100) {
    self.maxCacheSize = maxCacheSize
  }

  public func setMember(_ member: Member) async {
    // Add or update member in cache
    addMemberToCache(member)
  }

  public func getMember(withID id: String) async -> Member? {
    if let cachedMember = cachedMembers.first(where: { $0.member.id == id }) {
      // Update access time - this is critical for LRU to work correctly
      updateMemberAccessTime(cachedMember.member)
      return cachedMember.member
    }

    return nil
  }

  public func getAllMembers() async -> [Member] {
    return cachedMembers.map { $0.member }
  }

  public func clearCache() async {
    cachedMembers.removeAll()
  }

  private func addMemberToCache(_ member: Member) {
    // Check if member already exists in cache
    if let index = cachedMembers.firstIndex(where: { $0.member.id == member.id }) {
      // Update existing entry with current timestamp
      cachedMembers[index].lastAccessed = Date()
    } else {
      // Add new entry
      cachedMembers.append(CachedMember(member: member, lastAccessed: Date()))

      // If cache exceeds maximum size, remove oldest entries
      evictOldestIfNeeded()
    }
  }

  private func updateMemberAccessTime(_ member: Member) {
    if let index = cachedMembers.firstIndex(where: { $0.member.id == member.id }) {
      // Update the access time to current time
      cachedMembers[index].lastAccessed = Date()
    } else {
      // If member not in cache, add them
      addMemberToCache(member)
    }
  }

  private func evictOldestIfNeeded() {
    if cachedMembers.count > maxCacheSize {
      // Sort by last accessed time (oldest first)
      cachedMembers.sort { $0.lastAccessed < $1.lastAccessed }

      // Remove oldest entries until we're back to max size
      cachedMembers = Array(cachedMembers.suffix(maxCacheSize))
    }
  }
}

// Helper struct to track when members were last accessed
private struct CachedMember {
  let member: Member
  var lastAccessed: Date
}

// No need for Codable conformance since we're not persisting data
