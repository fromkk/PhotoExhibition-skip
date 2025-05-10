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
  }
#endif
