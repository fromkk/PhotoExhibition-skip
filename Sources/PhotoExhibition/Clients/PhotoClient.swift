import Foundation
import OSLog

#if SKIP
  import SkipFirebaseFirestore
#else
  import FirebaseFirestore
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PhotoClient")

// 展示会の写真を管理するクライアント
protocol PhotoClient: Sendable {
  func fetchPhotos(exhibitionId: String) async throws -> [Photo]
  func addPhoto(exhibitionId: String, path: String) async throws -> Photo
  func updatePhoto(exhibitionId: String, photoId: String, title: String?, description: String?)
    async throws
  func deletePhoto(exhibitionId: String, photoId: String) async throws
}

// 展示会の写真モデル
struct ExhibitionPhoto: Identifiable, Hashable, Sendable {
  let id: String
  let path: String?
  let createdAt: Date
  let updatedAt: Date

  init?(documentID: String, data: [String: Any]) {
    guard let createdAtTimestamp = data["createdAt"] as? Timestamp,
      let updatedAtTimestamp = data["updatedAt"] as? Timestamp
    else {
      return nil
    }

    self.id = documentID
    self.path = data["path"] as? String
    self.createdAt = createdAtTimestamp.dateValue()
    self.updatedAt = updatedAtTimestamp.dateValue()
  }
}

actor DefaultPhotoClient: PhotoClient {
  func fetchPhotos(exhibitionId: String) async throws -> [Photo] {
    logger.info("fetchPhotos for exhibition: \(exhibitionId)")

    let firestore = Firestore.firestore()
    let photosSnapshot = try await firestore.collection("exhibitions")
      .document(exhibitionId)
      .collection("photos")
      .order(by: "createdAt", descending: true)
      .getDocuments()

    var photos: [Photo] = []

    for document in photosSnapshot.documents {
      if let photo = Photo(documentID: document.documentID, data: document.data()) {
        photos.append(photo)
      }
    }

    return photos
  }

  func addPhoto(exhibitionId: String, path: String) async throws -> Photo {
    logger.info("addPhoto for exhibition: \(exhibitionId), path: \(path)")

    let firestore = Firestore.firestore()
    let photoData: [String: Any] = [
      "path": path,
      "createdAt": Timestamp(date: Date()),
      "updatedAt": Timestamp(date: Date()),
    ]

    let photoRef = try await firestore.collection("exhibitions")
      .document(exhibitionId)
      .collection("photos")
      .addDocument(data: photoData)

    guard let photo = Photo(documentID: photoRef.documentID, data: photoData) else {
      throw NSError(
        domain: "PhotoClient", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create photo object"])
    }

    return photo
  }

  func updatePhoto(exhibitionId: String, photoId: String, title: String?, description: String?)
    async throws
  {
    logger.info("updatePhoto for exhibition: \(exhibitionId), photoId: \(photoId)")

    let firestore = Firestore.firestore()
    var updateData: [String: Any] = [
      "updatedAt": Timestamp(date: Date())
    ]

    if let title = title {
      updateData["title"] = title
    }

    if let description = description {
      updateData["description"] = description
    }

    try await firestore.collection("exhibitions")
      .document(exhibitionId)
      .collection("photos")
      .document(photoId)
      .updateData(updateData)
  }

  func deletePhoto(exhibitionId: String, photoId: String) async throws {
    logger.info("deletePhoto for exhibition: \(exhibitionId), photoId: \(photoId)")

    let firestore = Firestore.firestore()
    try await firestore.collection("exhibitions")
      .document(exhibitionId)
      .collection("photos")
      .document(photoId)
      .delete()
  }
}
