import Foundation

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

protocol MemberUpdateClient: Sendable {
  func updateName(memberID: String, name: String) async throws -> Member
  func updateIcon(memberID: String, iconPath: String?) async throws -> Member
  func updateProfile(memberID: String, name: String, iconPath: String?) async throws -> Member
}

enum MemberUpdateClientError: Error, Sendable, LocalizedError {
  case updateFailed
  case memberNotFound
  case invalidData

  var errorDescription: String? {
    switch self {
    case .updateFailed:
      return "Failed to update profile"
    case .memberNotFound:
      return "Member information not found"
    case .invalidData:
      return "Invalid data"
    }
  }
}

actor DefaultMemberUpdateClient: MemberUpdateClient {
  func updateName(memberID: String, name: String) async throws -> Member {
    let db = Firestore.firestore()
    let memberRef = db.collection("members").document(memberID)

    // Prepare update data
    let updateData: [String: Any] = [
      "name": name,
      "updatedAt": Timestamp(date: Date()),
    ]

    // Update Firestore document
    try await memberRef.updateData(updateData)

    // Get updated data
    let document = try await memberRef.getDocument()

    guard let data = document.data() else {
      throw MemberUpdateClientError.memberNotFound
    }

    guard let member = Member(documentID: memberID, data: data) else {
      throw MemberUpdateClientError.invalidData
    }

    return member
  }

  func updateIcon(memberID: String, iconPath: String?) async throws -> Member {
    let db = Firestore.firestore()
    let memberRef = db.collection("members").document(memberID)

    // Prepare update data
    var updateData: [String: Any] = [
      "updatedAt": Timestamp(date: Date())
    ]

    if let iconPath = iconPath {
      updateData["icon"] = iconPath
    } else {
      // アイコンを削除する場合（nilの場合）
      updateData["icon"] = FieldValue.delete()
    }

    // Update Firestore document
    try await memberRef.updateData(updateData)

    // Get updated data
    let document = try await memberRef.getDocument()

    guard let data = document.data() else {
      throw MemberUpdateClientError.memberNotFound
    }

    guard let member = Member(documentID: memberID, data: data) else {
      throw MemberUpdateClientError.invalidData
    }

    return member
  }

  func updateProfile(memberID: String, name: String, iconPath: String?) async throws -> Member {
    let db = Firestore.firestore()
    let memberRef = db.collection("members").document(memberID)

    // Prepare update data
    var updateData: [String: Any] = [
      "name": name,
      "updatedAt": Timestamp(date: Date()),
    ]

    if let iconPath = iconPath {
      updateData["icon"] = iconPath
    } else {
      // アイコンを削除する場合（nilの場合）
      updateData["icon"] = FieldValue.delete()
    }

    // Update Firestore document
    try await memberRef.updateData(updateData)

    // Get updated data
    let document = try await memberRef.getDocument()

    guard let data = document.data() else {
      throw MemberUpdateClientError.memberNotFound
    }

    guard let member = Member(documentID: memberID, data: data) else {
      throw MemberUpdateClientError.invalidData
    }

    return member
  }
}
