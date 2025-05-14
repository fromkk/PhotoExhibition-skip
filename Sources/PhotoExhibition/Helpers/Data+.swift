#if !SKIP
  import CoreImage
  import Foundation
  import UniformTypeIdentifiers

  enum ImageFormat {
    case unknown, png, jpeg, gif, heic
  }

  enum ImageFormatError: Error {
    case unknownImageFormat
  }

  extension ImageFormatError: LocalizedError {
    var errorDescription: String? {
      switch self {
      case .unknownImageFormat:
        return String(
          localized:
            "Unsupported image format. Please select a JPEG, PNG, GIF or HEIC image."
        )
      }
    }
  }

  extension Data {
    var imageFormat: ImageFormat {
      var buffer = [UInt8](repeating: 0, count: 8)
      // 先頭8バイトを取得
      self.copyBytes(to: &buffer, count: 8)

      // PNG判定
      if buffer.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
        return .png
      }
      // JPEG判定（先頭2バイトのみチェック）
      else if buffer.starts(with: [0xFF, 0xD8]) {
        return .jpeg
      }
      // GIF判定（先頭6バイトをASCII文字列としてチェック）
      else if self.count >= 6,
        let header = String(data: self.prefix(6), encoding: .ascii),
        header.hasPrefix("GIF")
      {
        return .gif
      }

      guard let src = CGImageSourceCreateWithData(self as CFData, nil) else {
        return .unknown
      }

      // HEIC/HEIF であることを確認
      guard
        let uti = CGImageSourceGetType(src) as? String,
        UTType(uti)?.conforms(to: .heic) ?? false
      else {
        return .unknown
      }

      return .heic
    }

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

    var splitImages: (CGImage, CGImage)? {
      guard let src = CGImageSourceCreateWithData(self as CFData, nil) else {
        return nil
      }

      guard
        let properties = CGImageSourceCopyProperties(src, nil)
          as? [CFString: Any],
        let groups = properties[kCGImagePropertyGroups] as? [[CFString: Any]],
        let stereoPairGroup = groups.first(where: {
          $0[kCGImagePropertyGroupType] as? String
            == (kCGImagePropertyGroupTypeStereoPair as String)
        }),
        let leftIndex = stereoPairGroup[kCGImagePropertyGroupImageIndexLeft]
          as? Int,
        let rightIndex = stereoPairGroup[kCGImagePropertyGroupImageIndexRight]
          as? Int,
        let left = CGImageSourceCreateImageAtIndex(src, leftIndex, nil),
        let right = CGImageSourceCreateImageAtIndex(src, rightIndex, nil)
      else {
        return nil
      }
      return (left, right)
    }

    var orientation: CGImagePropertyOrientation? {
      guard
        let src = CGImageSourceCreateWithData(self as CFData, nil),
        let property = CGImageSourceCopyProperties(src, nil) as? [CFString: Any],
        let rawValue = property[kCGImagePropertyOrientation] as? UInt32
      else {
        return nil
      }
      return CGImagePropertyOrientation(rawValue: rawValue)
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
#endif
