import SwiftUI
import GutenbergLumenKit
import GutenbergArcadeUI

struct SplashView: View {
    let game: LumenGame
    var onStart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
                #if os(tvOS)
                .focusable(false)
                #endif

            VStack(spacing: 26) {
                VStack(spacing: 10) {
                    Text("ARCADE")
                        .font(.system(size: Layout.splashTitleSize, weight: .black, design: .rounded))
                        .tracking(4)
                        .modifier(NeonTitleStyle())

                    Text("LUMEN")
                        .font(.system(size: Layout.splashSubtitleSize, weight: .heavy, design: .rounded))
                        .tracking(10)
                        .foregroundStyle(Color.neonBlue.opacity(0.85))
                }

                previewGrid

                Text("Press a light to toggle it and its neighbors. Clear the board.")
                    .font(.callout.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: Layout.splashPanelWidth)

                if game.streak > 0 {
                    Text("STREAK: \(game.streak)")
                        .font(.headline.weight(.black).monospacedDigit())
                        .tracking(2)
                        .foregroundStyle(Color.neonSilver)
                        .shadow(color: .neonSilver.opacity(0.7), radius: 8)
                }

                HStack(spacing: 14) {
                    Button(action: onStart) {
                        NeonPrimaryButtonLabel("START", maxWidth: .infinity)
                    }
                    #if os(tvOS)
                    .buttonStyle(TVCompactButtonStyle(cornerRadius: 12))
                    #else
                    .buttonStyle(.plain)
                    #endif

                    HowToButton()
                }
                .frame(maxWidth: Layout.splashPanelWidth)
            }
            .modifier(NeonPanelStyle())
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }

    private var previewGrid: some View {
        let pattern: [[Bool]] = [
            [false, true, false],
            [true, true, true],
            [false, true, false],
        ]
        return VStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(pattern[row][col] ? Color.lumenLit : Color.lumenDim)
                            .frame(width: 28, height: 28)
                            .shadow(
                                color: pattern[row][col] ? Color.lumenLit.opacity(0.55) : .clear,
                                radius: 6
                            )
                    }
                }
            }
        }
        .padding(12)
    }
}
