import Foundation

#if !SKIP
enum ImageFormat {
  case unknown, png, jpeg, gif
}

enum ImageFormatError: Error {
  case unknownImageFormat
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
    return .unknown
  }
}
#endif
