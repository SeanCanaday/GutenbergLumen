import SwiftUI
import GutenbergLumenKit
import GutenbergArcadeUI

struct ContentView: View {
    @State private var game = LumenGame()
    @State private var showSplash = true
    @State private var celebrationToken = UUID()

    private var showsGameChrome: Bool { !showSplash }

    var body: some View {
        ZStack {
            SynthwaveBackground().ignoresSafeArea()

            if showsGameChrome {
                mainLayout
            }

            if game.didJustWin, showsGameChrome {
                WinCelebration(game: game) {
                    game.newGame()
                }
                .id(celebrationToken)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(8)
            }

            if showSplash {
                SplashView(game: game) {
                    game.newGame()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: game.didJustWin) { _, won in
            if won { celebrationToken = UUID() }
        }
    }

    private var mainLayout: some View {
        GeometryReader { geo in
            let pad = Layout.screenPadding
            let railW = min(200, max(160, geo.size.width * 0.22))

            HStack(alignment: .top, spacing: pad) {
                VStack(spacing: Layout.stackSpacing) {
                    statusBar
                    BoardView(game: game, isInteractive: !game.isCleared)
                        .frame(maxWidth: Layout.boardMaxWidth, maxHeight: .infinity)
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 0)
                }
                .layoutPriority(1)

                controlRail
                    .frame(width: railW)
            }
            .padding(pad)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(game.isCleared ? Color.lumenLit : Color.neonPink)
                .frame(width: 8, height: 8)
                .shadow(color: (game.isCleared ? Color.lumenLit : Color.neonPink).opacity(0.8), radius: 4)

            Text(game.isCleared ? "CLEARED!" : "\(game.litCount) LIGHTS ON")
                .font(.caption.weight(.black))
                .tracking(1)
                .foregroundStyle(game.isCleared ? Color.lumenLit : Color.neonPink.opacity(0.95))

            Spacer(minLength: 0)

            HowToButton()
        }
    }

    private var controlRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("ARCADE")
                    .font(.system(size: Layout.titleSize, weight: .black, design: .rounded))
                    .tracking(2)
                    .modifier(NeonTitleStyle())
                Text("LUMEN")
                    .font(.system(size: Layout.titleSize * 0.72, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(Color.neonBlue.opacity(0.85))
            }

            statsPanel

            ArcadeRailSection("DIFFICULTY") {
                NeonSegmentedPicker(
                    selection: Binding(
                        get: { game.difficulty },
                        set: { game.setDifficulty($0) }
                    ),
                    options: Array(Difficulty.allCases),
                    label: { $0.displayName }
                )
            }

            ArcadeRailSection("MOVES") {
                VStack(spacing: 8) {
                    railAction("Hint", systemImage: "lightbulb.fill", enabled: !game.isCleared) {
                        game.requestHint()
                    }
                    railAction("Reset", systemImage: "arrow.counterclockwise", enabled: !game.isCleared) {
                        game.reset()
                    }
                }
            }

            ArcadeRailSection("GAME") {
                ArcadeNewGameButton {
                    game.newGame()
                }
            }

            Spacer(minLength: 0)
        }
        .animation(.easeInOut(duration: 0.2), value: game.difficulty)
    }

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            statRow("MOVES", "\(game.moves)", color: .neonBlue)
            statRow("PAR", "\(game.par)", color: .neonPink)
            statRow("STREAK", "\(game.streak)", color: .neonMagenta)
            if let best = game.bestMoves {
                statRow("BEST", "\(best)", color: .neonSilver)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.synthNavy.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.neonBlue.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func statRow(_ label: String, _ value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption2.weight(.black))
                .tracking(1)
                .foregroundStyle(color.opacity(0.85))
            Spacer()
            Text(value)
                .font(.caption.weight(.black).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
    }

    private func railAction(
        _ title: String,
        systemImage: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.caption.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.synthPurple.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.neonBlue.opacity(0.45), lineWidth: 1)
                    )
            )
            .foregroundStyle(enabled ? Color.neonBlue : Color.neonBlue.opacity(0.35))
        }
        .disabled(!enabled)
        #if os(tvOS)
        .buttonStyle(TVCompactButtonStyle(cornerRadius: 8))
        #else
        .buttonStyle(.plain)
        #endif
    }
}
