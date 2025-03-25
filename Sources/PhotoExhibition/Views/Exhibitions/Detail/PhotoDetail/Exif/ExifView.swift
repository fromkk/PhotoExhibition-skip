#if !SKIP
  import OSLog
  import SwiftUI

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Exif")

  struct ExifItem: Hashable, Sendable {
    let name: String
    let value: String
  }

  struct ExifParser {
    func callAsFunction(_ string: String?) -> [ExifItem] {
      guard
        let data = string?.data(using: .utf8),
        let jsonDictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let exif = jsonDictionary["exif"] as? [String: Any]
      else {
        return []
      }

      logger.info("jsonDictionary \(String(describing: jsonDictionary))")
      var result: [ExifItem] = []
      if let model = exif["Model"] as? String {
        result.append(ExifItem(name: String(localized: "Exif Model"), value: model))
      }

      if let lensMake = exif["LensMake"] as? String, let lensModel = exif["LensModel"] as? String {
        result.append(
          ExifItem(name: String(localized: "Exif Lens"), value: "\(lensMake) \(lensModel)"))
      }

      if let focalLength = exif["FocalLength"] as? String {
        result.append(ExifItem(name: String(localized: "Exif Focal Length"), value: focalLength))
      }

      if let shutterSpeed = exif["ShutterSpeed"] as? String {
        result.append(ExifItem(name: String(localized: "Exif Shutter Speed"), value: shutterSpeed))
      }

      if let fNumber = exif["FNumber"] as? Double ?? exif["Aperture"] as? Double {
        result.append(ExifItem(name: String(localized: "Exif F Number"), value: "\(fNumber)"))
      }

      if let iso = exif["ISO"] as? Int {
        result.append(ExifItem(name: String(localized: "Exif ISO"), value: "\(iso)"))
      }

      if let dateInfo = exif["DateTimeOriginal"] as? [String: Any],
        let rawValue = dateInfo["rawValue"] as? String
      {
        result.append(ExifItem(name: String(localized: "Exif Create Date"), value: rawValue))
      }
      return result
    }
  }

  @Observable final class ExifStore: Store {
    let photo: Photo
    let items: [ExifItem]
    let analyticsClient: any AnalyticsClient
    init(photo: Photo, analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()) {
      self.photo = photo
      self.analyticsClient = analyticsClient

      let parse = ExifParser()
      self.items = parse(photo.metadata)
    }

    enum Action {
      case task
    }
    func send(_ action: Action) {
      switch action {
      case .task:
        Task {
          await analyticsClient.analyticsScreen(name: "ExifView")
        }
      }
    }
  }

  struct ExifView: View {
    @Bindable var store: ExifStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
      NavigationStack {
        List {
          ForEach(store.items, id: \.self) { item in
            HStack {
              Text(item.name)
                .fontWeight(.semibold)

              Text(item.value)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
          }
        }
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button {
              Task {
                dismiss()
              }
            } label: {
              Image(systemName: SystemImageMapping.getIconName(from: "xmark"))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close"))
          }
        }
        .navigationTitle(Text("Information"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
          store.send(.task)
        }
      }
    }
  }
#endif
