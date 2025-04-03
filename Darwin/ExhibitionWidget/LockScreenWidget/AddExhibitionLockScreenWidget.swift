import SwiftUI
import WidgetKit

struct AddExhibitionLockScreenProvider: TimelineProvider {
  func placeholder(in context: Context) -> BasicEntry {
    BasicEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (BasicEntry) -> Void) {
    let entry = BasicEntry(date: Date())
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [BasicEntry] = []

    let currentDate = Date()
    for hourOffset in 0..<5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = BasicEntry(date: entryDate)
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct BasicEntry: TimelineEntry {
  let date: Date
}

struct LockScreenWidgetView: View {
  @Environment(\.widgetFamily) var family
  var entry: AddExhibitionLockScreenProvider.Entry

  var body: some View {
    if family == .accessoryCircular {
      Image(systemName: "plus")
        .widgetURL(URL(string: "exhivision://add_exhibition")!)
    }
  }
}

public struct AddExhibitionLockScreenWidget: Widget {
  public init() {}

  public let kind: String = "LockScreenWidgetView"

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: AddExhibitionLockScreenProvider()) { entry in
      if #available(iOS 17.0, *) {
        LockScreenWidgetView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        LockScreenWidgetView(entry: entry)
          .padding()
          .background()
      }
    }
    .configurationDisplayName("exhivision")
    .description("Add Exhibition")
    .supportedFamilies([
      .accessoryCircular
    ])
  }
}

#Preview(as: .systemSmall) {
  AddExhibitionLockScreenWidget()
} timeline: {
  BasicEntry(date: .now)
  BasicEntry(date: .now)
}
