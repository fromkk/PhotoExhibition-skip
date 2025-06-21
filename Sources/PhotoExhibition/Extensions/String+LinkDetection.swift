// This link detection relies on APIs that are unavailable in Skip builds.
#if SKIP
import Foundation

extension String {
  /// Returns a plain attributed string without link attributes when built for Skip.
  var linkified: AttributedString { AttributedString(self) }
}
#else
import Foundation

extension String {
  /// Returns an `AttributedString` where URL strings are converted to tappable links.
  var linkified: AttributedString {
    var attributed = AttributedString(self)
    let types = NSTextCheckingResult.CheckingType.link.rawValue
    if let detector = try? NSDataDetector(types: types) {
      let nsRange = NSRange(startIndex..<endIndex, in: self)
      for match in detector.matches(in: self, options: [], range: nsRange) {
        guard let url = match.url,
          let range = Range(match.range, in: self)
        else { continue }
        attributed[range].link = url
      }
    }
    return attributed
  }
}
#endif
