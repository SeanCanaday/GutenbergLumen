import SwiftUI
import GutenbergLumenKit
import GutenbergArcadeUI

struct BoardView: View {
    let game: LumenGame
    var isInteractive: Bool = true

    var body: some View {
        GeometryReader { geo in
            let n = game.boardSize
            let gap = Layout.cellSpacing
            let available = min(geo.size.width, geo.size.height)
            let side = max(10, floor((available - gap * CGFloat(n - 1)) / CGFloat(n)))

            VStack(spacing: gap) {
                ForEach(0..<n, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<n, id: \.self) { col in
                            cell(row: row, col: col, side: side)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private func cell(row: Int, col: Int, side: CGFloat) -> some View {
        let isLit = game.board.isLit(row: row, col: col)
        let showHint = game.hintCell == Cell(row: row, col: col)

        if isInteractive {
            Button {
                game.press(row: row, col: col)
            } label: {
                Color.clear
            }
            .buttonStyle(CellButtonStyle(isLit: isLit, side: side))
            .overlay {
                if showHint {
                    HintRing(side: side)
                }
            }
            .accessibilityLabel("Row \(row + 1), column \(col + 1)")
            .accessibilityValue(isLit ? "on" : "off")
        } else {
            RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                .fill(isLit ? Color.lumenLit : Color.lumenDim)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                        .strokeBorder(Color.neonBlue.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: isLit ? Color.lumenLit.opacity(0.6) : .clear, radius: isLit ? 12 : 0)
                .frame(width: side, height: side)
                .accessibilityHidden(true)
        }
    }
}

private struct HintRing: View {
    let side: CGFloat
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
            .strokeBorder(Color.neonBlue, lineWidth: 4)
            .frame(width: side, height: side)
            .scaleEffect(pulse ? 1.12 : 0.98)
            .opacity(pulse ? 0.4 : 1.0)
            .shadow(color: .neonBlue.opacity(0.7), radius: 8)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

/// Lit / dim tile that works with tvOS focus, Mac click, and iOS tap.
struct CellButtonStyle: ButtonStyle {
    let isLit: Bool
    let side: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        CellSurface(isLit: isLit, side: side, isPressed: configuration.isPressed)
    }

    private struct CellSurface: View {
        let isLit: Bool
        let side: CGFloat
        let isPressed: Bool
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                .fill(isLit ? Color.lumenLit : Color.lumenDim)
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                        .strokeBorder(
                            isFocused ? Color.neonPink : Color.neonBlue.opacity(0.35),
                            lineWidth: isFocused ? 3 : 1
                        )
                )
                .shadow(color: isLit ? Color.lumenLit.opacity(0.6) : .clear, radius: isLit ? 12 : 0)
                .frame(width: side, height: side)
                .scaleEffect(isPressed ? 0.94 : (isFocused ? 1.08 : 1.0))
                .animation(.easeOut(duration: 0.12), value: isFocused)
                .animation(.easeOut(duration: 0.08), value: isPressed)
                .animation(.easeInOut(duration: 0.15), value: isLit)
        }
    }
}
