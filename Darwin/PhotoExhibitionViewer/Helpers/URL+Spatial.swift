import CoreImage
import Foundation
import UniformTypeIdentifiers

extension Data {
  var isSpatialPhoto: Bool {
    // Image I/O でコンテナを開く
    guard let src = CGImageSourceCreateWithData(self as CFData, nil) else {
      return false
    }

    // HEIC/HEIF であることを確認
    guard
      let utiString = CGImageSourceGetType(src) as? String,
      let uti = UTType(utiString),
      UTType.heic.conforms(to: uti)
    else {
      return false
    }

    // マルチイメージ HEIC で、「少なくとも左右 2 枚」を持っていること
    guard
      CGImageSourceGetCount(src) >= 2,
      let properties = CGImageSourceCopyProperties(src, nil) as? [CFString: Any],
      let groups = properties[kCGImagePropertyGroups] as? [[CFString: Any]]
    else {
      return false
    }

    // GroupTypeStereoPairであること
    return groups.contains { dict in
      (dict[kCGImagePropertyGroupType] as? String)
        == (kCGImagePropertyGroupTypeStereoPair as String)
    }
  }
}

extension URL {
  var isSpatialPhoto: Bool {
    guard let data = try? Data(contentsOf: self) else {
      return false
    }
    return data.isSpatialPhoto
  }
}
