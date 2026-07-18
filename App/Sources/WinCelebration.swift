import SwiftUI
import GutenbergArcadeUI

/// Cleared-board overlay — shared shell with Lumen-specific copy.
struct WinCelebration: View {
    let game: LumenGame
    var onPlayAgain: () -> Void

    var body: some View {
        ArcadeCelebrationShell(
            vibe: .win,
            copy: ArcadeCelebrationCopy(
                headline: headline,
                subline: "SOLVED IN \(game.moves) · PAR \(game.par)",
                detail: detail,
                tagline: game.moves <= game.par ? "TOTALLY RAD!" : "LIGHTS OUT!",
                accent: .neonPink,
                secondary: .neonBlue
            ),
            burstCenterY: 0.42,
            onPlayAgain: onPlayAgain
        )
    }

    private var headline: String {
        if game.moves <= game.par { return "PERFECT!" }
        if game.moves <= game.par + 2 { return "CLEARED!" }
        return "NICE WORK!"
    }

    private var detail: String? {
        var parts: [String] = []
        if game.hintsUsed > 0 {
            parts.append("\(game.hintsUsed) HINT\(game.hintsUsed == 1 ? "" : "S")")
        }
        if game.streak > 0 {
            parts.append("STREAK \(game.streak)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
