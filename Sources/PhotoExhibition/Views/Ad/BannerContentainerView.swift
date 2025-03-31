import SwiftUI

#if SKIP
import androidx.compose.runtime.Composable
#else
import UIKit
@preconcurrency import GoogleMobileAds
#endif

struct BannerContentainerView: View {

  var adUnitId: String
  init(adUnitId: String) {
    self.adUnitId = adUnitId
  }

  #if SKIP
  @Composable override func ComposeContent(context: ComposeContext) {
    BannerContentView(adUnitId: adUnitId)
  }
  #else
  @State var isAdLoaded: Bool = true
  var body: some View {
    HStack {
      if isAdLoaded {
        Spacer()
        BannerContentView(AdSizeBanner, adUnitId: adUnitId, isAdLoaded: $isAdLoaded)
          .frame(width: AdSizeBanner.size.width, height: AdSizeBanner.size.height)
        Spacer()
      }
    }
    .frame(maxWidth: .infinity)
  }
  #endif
}

#if !SKIP
// [START create_banner_view]
struct BannerContentView: UIViewRepresentable {
  @Binding var isAdLoaded: Bool
  let adSize: AdSize
  var adUnitId: String

  init(_ adSize: AdSize, adUnitId: String, isAdLoaded: Binding<Bool>) {
    self.adSize = adSize
    self.adUnitId = adUnitId
    _isAdLoaded = isAdLoaded
  }

  func makeUIView(context: Context) -> UIView {
    // Wrap the BannerView in a UIView. BannerView automatically reloads a new ad when its
    // frame size changes; wrapping in a UIView container insulates the BannerView from size
    // changes that impact the view returned from makeUIView.
    let view = UIView()
    view.addSubview(context.coordinator.bannerView)
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    context.coordinator.bannerView.adSize = adSize
  }

  func makeCoordinator() -> BannerCoordinator {
    return BannerCoordinator(self, adUnitId: adUnitId, isAdLoaded: $isAdLoaded)
  }
  // [END create_banner_view]

  // [START create_banner]
  @MainActor
  class BannerCoordinator: NSObject, BannerViewDelegate {
    private(set) lazy var bannerView: BannerView = {
      let banner = BannerView(adSize: parent.adSize)
      // [START load_ad]
      banner.adUnitID = adUnitId
      banner.load(Request())
      // [END load_ad]
      // [START set_delegate]
      banner.delegate = self
      // [END set_delegate]
      return banner
    }()

    let parent: BannerContentView
    private let adUnitId: String
    @Binding var isAdLoaded: Bool

    init(_ parent: BannerContentView, adUnitId: String, isAdLoaded: Binding<Bool>) {
      self.parent = parent
      self.adUnitId = adUnitId
      _isAdLoaded = isAdLoaded
    }
    // [END create_banner]

    // MARK: - BannerViewDelegate methods

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
      print("DID RECEIVE AD.")
      bannerView.isHidden = false
      isAdLoaded = true
    }

    func bannerView(
      _ bannerView: BannerView, didFailToReceiveAdWithError error: Error
    ) {
      print("FAILED TO RECEIVE AD: \(error.localizedDescription)")
      bannerView.isHidden = true
      isAdLoaded = false
    }
  }
}
#endif
