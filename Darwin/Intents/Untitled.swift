import AppIntents

struct ExhibitionShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddExhibitionIntent(),
      phrases: ["Add Exhibition"],
      shortTitle: "Add Exhibition",
      systemImageName: "plus"
    )
  }
}
