import SwiftUI

@main
struct GutenbergLumenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        #if os(macOS)
        .defaultSize(width: 720, height: 840)
        #endif
    }
}
