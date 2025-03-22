import SkipKit
import SwiftUI

struct FootprintView: View {
  let footprint: Footprint
  let imageCache: any StorageImageCacheProtocol
  @State private var userIconURL: URL? = nil
  @State private var isLoadingIcon: Bool = false
  @State private var userName: String? = nil

  var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(Color.gray.opacity(0.3))
        .frame(width: 40, height: 40)
        .overlay {
          Image(systemName: SystemImageMapping.getIconName(from: "person.fill"))
            .foregroundColor(.gray)
        }

      VStack(alignment: .leading, spacing: 4) {
        Text(userName ?? "Unknown User")
          .font(.subheadline)
          .bold()
          .foregroundColor(userName == nil ? .gray : .primary)

        Text(dateFormatter.string(from: footprint.createdAt))
          .font(.caption)
          .foregroundColor(.gray)
      }

      Spacer()
    }
    .padding(.vertical, 8)
    .task {
      // loadUserData()
    }
  }

  private func loadUserData() {
    // TODO: ユーザー情報を取得する
  }

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }
}

#Preview {
  FootprintView(
    footprint: Footprint(
      id: "preview",
      exhibitionId: "ex123",
      userId: "user456",
      createdAt: Date()
    ),
    imageCache: StorageImageCache.shared
  )
  .padding()
  .previewLayout(.sizeThatFits)
}
