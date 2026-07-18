import SwiftUI
import GutenbergArcadeUI

enum Layout {
    static var screenPadding: CGFloat { ArcadeLayout.screenPadding }

    static var titleSize: CGFloat {
        #if os(tvOS)
        30
        #else
        24
        #endif
    }

    static var splashTitleSize: CGFloat { ArcadeLayout.splashTitleSize }
    static var splashSubtitleSize: CGFloat { ArcadeLayout.splashSubtitleSize }
    static var splashPanelWidth: CGFloat { ArcadeLayout.splashPanelWidth }

    static var cellSpacing: CGFloat {
        #if os(tvOS)
        18
        #else
        10
        #endif
    }

    static var stackSpacing: CGFloat {
        #if os(tvOS)
        10
        #else
        20
        #endif
    }

    static var boardMaxWidth: CGFloat {
        #if os(tvOS)
        720
        #else
        520
        #endif
    }

    static var controlMaxWidth: CGFloat {
        #if os(tvOS)
        460
        #else
        360
        #endif
    }
}

extension Color {
    /// Lit tile — neon pink against the synthwave field.
    static let lumenLit = Color.neonPink
    static let lumenDim = Color.synthNavy.opacity(0.85)
}

enum HelpText {
    static let howToTitle = "How to play"
    static let howTo = """
        Press a light to toggle it and its neighbors. Clear every light to win.

        • Par is the shortest known solution for this board.
        • Hint shows one correct next press.
        • Easy / Medium / Hard change how many presses the puzzle needs.
        """
}

struct HowToButton: View {
    @State private var show = false

    var body: some View {
        Button {
            show = true
        } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.neonBlue.opacity(0.85))
        }
        #if os(tvOS)
        .buttonStyle(TVCompactButtonStyle(cornerRadius: 16))
        #else
        .buttonStyle(.plain)
        #endif
        #if os(macOS)
        .help(HelpText.howTo)
        #endif
        .alert(HelpText.howToTitle, isPresented: $show) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text(HelpText.howTo)
        }
    }
}
