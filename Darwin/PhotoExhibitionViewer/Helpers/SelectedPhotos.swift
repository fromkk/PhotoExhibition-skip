import Viewer

final class SelectedPhotos {
  var exhibitionId: String
  var photoId: String
  var photos: [Photo]

  init(exhibitionId: String, photoId: String, photos: [Photo]) {
    self.exhibitionId = exhibitionId
    self.photoId = photoId
    self.photos = photos
  }
}
