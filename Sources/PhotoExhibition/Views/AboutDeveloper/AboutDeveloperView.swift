import SwiftUI

#if !SKIP
  import StoreKit
#endif

@Observable
final class AboutDeveloperStore {
  let developerInfo: DeveloperInfo?
  let purchaseLogClient: PurchaseLogClient
  var isPurchasing: Bool = false

  init(
    developerInfoClient: DeveloperInfoClient = .liveValue,
    purchaseLogClient: PurchaseLogClient = .liveValue
  ) {
    developerInfo = developerInfoClient.developerInfo()
    self.purchaseLogClient = purchaseLogClient
  }

  var error: (any Error)?

  #if !SKIP
    func purchaseStarted() {
      isPurchasing = true
    }

    func purchaseCompletion(
      _ product: Product,
      _ result: Result<Product.PurchaseResult, any Error>
    ) {
      defer {
        isPurchasing = false
      }
      switch result {
      case .success(let purchaseResult):
        switch purchaseResult {
        case .success:
          purchaseLogClient.purchased(product.id)
        case .userCancelled:
          break
        case .pending:
          break
        @unknown default:
          break
        }
      case .failure(let error):
        self.error = error
      }
    }
  #endif
}

struct AboutDeveloperView: View {
  @Bindable var store: AboutDeveloperStore
  @Environment(\.openURL) var openURL

  init(store: AboutDeveloperStore) {
    self.store = store
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        AsyncImage(url: store.developerInfo?.iconUrl) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .frame(width: 128, height: 128)
              .clipShape(Circle())
          default:
            ProgressView()
          }
        }

        descriptionLabel
          .font(.body)
          .frame(maxWidth: .infinity, alignment: .leading)
          .multilineTextAlignment(.leading)

        #if !SKIP
          if let productId = store.developerInfo?.supportProductId {
            ProductView(id: productId)
              .padding(8)
              .clipShape(RoundedRectangle(cornerRadius: 8))
          }
        #endif

        HStack(spacing: 16) {
          if let xUrl = store.developerInfo?.xUrl {
            Button {
              openURL(xUrl)
            } label: {
              Text("\u{1D54F}")
                .font(.headline)
            }
            .accessibilityLabel(Text(verbatim: "X"))
          }

          if let websiteUrl = store.developerInfo?.websiteUrl {
            Button {
              openURL(websiteUrl)
            } label: {
              Text("\(Image(systemName: "house"))")
                .font(.body)
            }
            .accessibilityLabel(
              Text("Website", tableName: "AboutDeveloper", bundle: .module)
            )
          }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)

        Section {
          if let apps = store.developerInfo?.apps {
            ScrollView(.horizontal) {
              LazyHStack {
                ForEach(apps, id: \.self) { app in
                  AppItemView(app: app)
                }
              }
            }
          }
        } header: {
          Text("Other apps", tableName: "AboutDeveloper", bundle: .module)
            .font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        VStack(alignment: .center, spacing: 8) {
          if let termsOfRulesUrl = store.developerInfo?.termsOfRulesUrl {
            Button {
              openURL(termsOfRulesUrl)
            } label: {
              Text(
                "Terms of rules",
                tableName: "AboutDeveloper",
                bundle: .module
              )
              .font(.body)
            }
          }

          if let privacyPolicyUrl = store.developerInfo?.privacyPolicyUrl {
            Button {
              openURL(privacyPolicyUrl)
            } label: {
              Text(
                "Privacy policy",
                tableName: "AboutDeveloper",
                bundle: .module
              )
              .font(.body)
            }
          }
        }
      }
      .padding(16)
    }
    .navigationTitle(title)
    #if !SKIP
      .onInAppPurchaseCompletion { product, result in
        store.purchaseCompletion(product, result)
      }
    #endif
    .alert(
      "Error",
      isPresented: Binding(
        get: { store.error != nil },
        set: { if !$0 { store.error = nil } }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(store.error?.localizedDescription ?? "An error occurred")
    }
  }

  var title: Text {
    if let title = store.developerInfo?.title {
      Text(title)
    } else {
      Text("About developer", tableName: "AboutDeveloper", bundle: .module)
    }
  }

  var descriptionLabel: Text {
    if let description = store.developerInfo?.description {
      Text(description)
    } else {
      Text("Support description", tableName: "AboutDeveloper", bundle: .module)
    }
  }
}

struct AppItemView: View {
  let app: DeveloperInfo.App
  @Environment(\.openURL) var openURL

  var body: some View {
    VStack(alignment: .center, spacing: 8) {
      AsyncImage(url: app.iconUrl) { phase in
        switch phase {
        case .success(let image):
          image
            .resizable()
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        default:
          ProgressView()
        }
      }

      Text(app.name)
        .font(.body)

      Button {
        openURL(app.appStoreUrl)
      } label: {
        Text("App Store")
          .font(.callout)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(8)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

#Preview("ja") {
  NavigationStack {
    AboutDeveloperView(
      store: AboutDeveloperStore(
        developerInfoClient: .init(
          developerInfo: {
            DeveloperInfo(
              title: "開発者について",
              description: "説明文",
              iconUrl: URL(
                string: "https://fromkk.me/assets/kakkun-1db32db2.png"
              )!,
              xUrl: URL(string: "https://x.com/fromkk")!,
              websiteUrl: URL(string: "https://fromkk.me/")!,
              termsOfRulesUrl: URL(
                string: "https://type-markdown.app/terms.html"
              )!,
              privacyPolicyUrl: URL(
                string: "https://type-markdown.app/privacy.html"
              )!,
              apps: [
                .init(
                  name: "exhivision",
                  description: "自分だけの写真展が開けるアプリ",
                  iconUrl: URL(
                    string: "https://fromkk.me/assets/exhivision-1e8c8f39.png"
                  )!,
                  appStoreUrl: URL(
                    string: "https://apps.apple.com/app/id6743517041"
                  )!,
                  appStoreId: "6743517041"
                )
              ],
              supportProductId: "me.fromkk.exhivision.support1",
            )
          })
      )
    )
  }
  .environment(\.locale, Locale(identifier: "ja_JP"))
}

#Preview("en") {
  NavigationStack {
    AboutDeveloperView(store: AboutDeveloperStore())
  }
  .environment(\.locale, Locale(identifier: "en_US"))
}
