import ScreenshotCleanerUI
import SwiftUI

@main
struct ScreenshotCleanerApp: App {
    @State private var store = Store()

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environment(store)
        } label: {
            Image(nsImage: MenuBarIcon.image(hasPending: !store.items.isEmpty))
        }
        .menuBarExtraStyle(.window)
    }
}
