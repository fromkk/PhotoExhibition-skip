import OSLog
import SwiftUI

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "MemberRowView")

struct MemberRowView: View {
  let userId: String
  let imageCache: any StorageImageCacheProtocol
  let memberCache: any MemberCacheClient
  let membersClient: any MembersClient
  @State private var userIconURL: URL? = nil
  @State private var isLoadingIcon: Bool = false
  @State private var userName: String? = nil

  init(
    userId: String,
    imageCache: any StorageImageCacheProtocol = StorageImageCache(
      storageClient: DefaultStorageClient.shared),
    memberCache: any MemberCacheClient = DefaultMemberCacheClient.shared,
    membersClient: any MembersClient = DefaultMembersClient()
  ) {
    self.userId = userId
    self.imageCache = imageCache
    self.memberCache = memberCache
    self.membersClient = membersClient
  }

  var body: some View {
    HStack(spacing: 8) {
      if let userIconURL {
        AsyncImage(url: userIconURL) { image in
          image.resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        } placeholder: {
          ProgressView()
        }
      } else {
        ZStack {
          Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 32, height: 32)
          Image(systemName: SystemImageMapping.getIconName(from: "person.fill"))
            .foregroundColor(.gray)
        }
      }

      Group {
        if let userName {
          Text(userName)
        } else {
          Text("Unknown User")
            .font(.subheadline)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .task {
      do {
        let userIds: [String] = [userId]
        if let member = await memberCache.getMember(withID: userId) {
          userName = member.name
          if let iconPath = member.iconPath {
            userIconURL = try await imageCache.getImageURL(for: iconPath)
          }
        } else if let member = try await membersClient.fetch(userIds).first {
          await memberCache.setMember(member)
          userName = member.name
          if let iconPath = member.iconPath {
            userIconURL = try await imageCache.getImageURL(for: iconPath)
          }
        }
      } catch {
        logger.error("error \(error.localizedDescription)")
      }
    }
  }
}
