import Foundation

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

public protocol MemberUpdateClient: Sendable {
  func updateName(memberID: String, name: String) async throws -> Member
  func updateIcon(memberID: String, iconPath: String?) async throws -> Member
  func updateProfile(memberID: String, name: String, iconPath: String?) async throws -> Member
  func postAgreement(memberID: String) async throws -> Member
}

public enum MemberUpdateClientError: Error, Sendable, LocalizedError {
  case updateFailed
  case memberNotFound
  case invalidData

  public var errorDescription: String? {
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

public actor DefaultMemberUpdateClient: MemberUpdateClient {
  public init() {}

  public func updateName(memberID: String, name: String) async throws -> Member {
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

  public func updateIcon(memberID: String, iconPath: String?) async throws -> Member {
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
    updateData["icon_256x256"] = FieldValue.delete()
    updateData["icon_512x512"] = FieldValue.delete()
    updateData["icon_1024x1024"] = FieldValue.delete()

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

  public func updateProfile(memberID: String, name: String, iconPath: String?) async throws
    -> Member
  {
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

  public func postAgreement(memberID: String) async throws -> Member {
    let db = Firestore.firestore()
    let memberRef = db.collection("members").document(memberID)

    // Prepare update data
    let updateData: [String: Any] = [
      "postAgreement": true,
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
}
