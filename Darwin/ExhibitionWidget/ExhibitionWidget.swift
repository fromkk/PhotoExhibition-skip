import SwiftUI
import WidgetClients
import WidgetKit

struct ExhibitionWidgetProvider: TimelineProvider {
  private let exhibitionsClient: any WidgetExhibitionsClient
  private let storageClient: any WidgetStorageClient

  init(
    exhibitionsClient: any WidgetExhibitionsClient = DefaultWidgetExhibitionsClient(),
    storageClient: any WidgetStorageClient = DefaultWidgetStorageClient()
  ) {
    self.exhibitionsClient = exhibitionsClient
    self.storageClient = storageClient
  }

  func placeholder(in context: Context) -> ExhibitionEntry {
    ExhibitionEntry(date: Date(), exhibition: nil, coverImage: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (ExhibitionEntry) -> Void) {
    let entry = ExhibitionEntry(date: Date(), exhibition: nil, coverImage: nil)
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    Task {
      do {
        let now = Date()
        let (exhibitions, _) = try await exhibitionsClient.fetch(now: now, cursor: nil)

        if let exhibition = exhibitions.shuffled().first {
          var coverImage: UIImage? = nil

          if let coverPath = exhibition.coverPath {
            do {
              let url = try await storageClient.url(coverPath)
              if let (data, _) = try? await URLSession.shared.data(from: url),
                let image = UIImage(data: data)
              {
                coverImage = image
              }
            } catch {
              print("Failed to load cover image: \(error)")
            }
          }

          let entry = ExhibitionEntry(date: now, exhibition: exhibition, coverImage: coverImage)
          let nextUpdate =
            Calendar.current.date(byAdding: .hour, value: 1, to: now)
            ?? now.addingTimeInterval(3600)
          let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
          completion(timeline)
        } else {
          let entry = ExhibitionEntry(date: now, exhibition: nil, coverImage: nil)
          let nextUpdate =
            Calendar.current.date(byAdding: .hour, value: 1, to: now)
            ?? now.addingTimeInterval(3600)
          let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
          completion(timeline)
        }
      } catch {
        let entry = ExhibitionEntry(date: Date(), exhibition: nil, coverImage: nil)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
      }
    }
  }
}

struct ExhibitionEntry: TimelineEntry {
  let date: Date
  let exhibition: WidgetExhibition?
  let coverImage: UIImage?

  var openURL: URL? {
    if let exhibitionId = exhibition?.id {
      return URL(string: "exhivision://exhibition/\(exhibitionId)")
    } else {
      return nil
    }
  }
}

struct ExhibitionWidgetEntryView: View {
  var entry: ExhibitionWidgetProvider.Entry

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }

  var body: some View {
    if let exhibition = entry.exhibition {
      GeometryReader { geometry in
        ZStack(alignment: .bottom) {
          // Background image
          if let coverImage = entry.coverImage {
            Image(uiImage: coverImage)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: geometry.size.width, height: geometry.size.height)
              .clipped()
          } else {
            Color.gray
          }

          // Gradient overlay for better text visibility
          LinearGradient(
            gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: geometry.size.height * 0.6)

          // Text content
          VStack(alignment: .leading, spacing: 4) {
            Text(
              String(
                format: String(localized: "%@ - %@"), dateFormatter.string(from: exhibition.from),
                dateFormatter.string(from: exhibition.to))
            )
            .font(.caption)
            .foregroundColor(.white)

            Text(exhibition.name)
              .font(.headline)
              .foregroundColor(.white)
              .lineLimit(2)
          }
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    } else {
      VStack {
        Text("No Exhibition", comment: "Displayed when no exhibition is available")
          .font(.headline)
      }
    }
  }
}

struct ExhibitionWidget: Widget {
  let kind: String = "ExhibitionWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ExhibitionWidgetProvider()) { entry in
      ExhibitionWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(entry.openURL)
    }
    .configurationDisplayName("Exhibition")
    .description("Shows information about current exhibitions.")
    .supportedFamilies([
      .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
    ])
    .contentMarginsDisabled()
  }
}

#Preview(as: .systemSmall) {
  ExhibitionWidget()
} timeline: {
  let now = Date()
  let member = WidgetMember(
    id: "preview",
    name: "Preview User",
    createdAt: now,
    updatedAt: now
  )

  let exhibition = WidgetExhibition(
    id: "preview",
    name: "Sample Exhibition",
    description: "This is a sample exhibition",
    from: now.addingTimeInterval(-86400),
    to: now.addingTimeInterval(86400),
    organizer: member,
    coverImagePath: "https://example.com/image.jpg",
    status: .published,
    createdAt: now,
    updatedAt: now
  )

  ExhibitionEntry(date: now, exhibition: exhibition, coverImage: nil)
}
