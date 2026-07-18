import Foundation

/// A deterministic puzzle for a given day. The same `id` always yields the same
/// starting board on every device — that's what makes it a shared daily puzzle.
public struct DailyPuzzle: Equatable, Sendable {
    /// Day key, e.g. "2026-06-25".
    public let id: String
    public let size: Int
    /// Starting (scrambled) board.
    public let board: Board
    /// A known-valid solution: pressing exactly these cells clears the board.
    public let solution: [Cell]

    public var parMoves: Int { solution.count }
}

/// How hard a generated puzzle is, expressed as the number of moves its
/// solution takes (its "par"). More moves = harder.
public enum Difficulty: String, CaseIterable, Sendable, Identifiable, Hashable {
    case easy
    case medium
    case hard

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    /// Target solution length (par) range, before clamping to the board size.
    public var parRange: ClosedRange<Int> {
        switch self {
        case .easy: return 3...6
        case .medium: return 7...11
        case .hard: return 12...18
        }
    }
}

public enum DailyPuzzleGenerator {

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        var cal = calendar
        cal.timeZone = calendar.timeZone
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Difficulty scales gently across the week (Mon easiest → weekend harder),
    /// bounded so it always stays solvable and fair.
    private static func pressBudget(size: Int, rng: inout SeededRNG) -> Int {
        let minPresses = max(3, size)
        let maxPresses = size * size - 2
        guard maxPresses > minPresses else { return minPresses }
        return Int.random(in: minPresses...maxPresses, using: &rng)
    }

    public static func puzzle(for date: Date = Date(),
                              calendar: Calendar = .current,
                              size: Int = 5) -> DailyPuzzle {
        puzzle(forDayKey: dayKey(for: date, calendar: calendar), size: size)
    }

    /// A stable, distinct opening pattern for a given index. `puzzle(patternIndex: 2)`
    /// always yields the same solvable board — handy for cycling through a fixed
    /// set of openings.
    public static func puzzle(patternIndex: Int, size: Int = 5) -> DailyPuzzle {
        puzzle(forDayKey: "pattern-\(patternIndex)", size: size)
    }

    /// A puzzle built directly from a 64-bit seed (reproducible per seed).
    public static func puzzle(seed: UInt64, size: Int = 5) -> DailyPuzzle {
        puzzle(forDayKey: "seed-\(seed)", size: size)
    }

    /// A fresh, effectively-unlimited random opening. Each call draws a new seed,
    /// so you get continuous variety rather than a fixed set — still guaranteed
    /// solvable by construction.
    public static func randomPuzzle(size: Int = 5) -> DailyPuzzle {
        var system = SystemRandomNumberGenerator()
        return puzzle(seed: system.next(), size: size)
    }

    /// A reproducible puzzle whose solution uses exactly `moveCount` distinct
    /// presses (i.e. par == moveCount, clamped to the board). This is how we get
    /// precise difficulty control.
    public static func puzzle(seed: UInt64, size: Int = 5, moveCount: Int) -> DailyPuzzle {
        var rng = SeededRNG(seed: seed)
        let n = size * size
        let count = max(1, min(moveCount, n))

        // Pick `count` distinct cells via a partial Fisher–Yates shuffle.
        var indices = Array(0..<n)
        for i in 0..<count {
            let j = Int.random(in: i..<n, using: &rng)
            indices.swapAt(i, j)
        }
        var chosen = Set(indices.prefix(count))

        var board = Board(size: size)
        for idx in chosen { board.press(row: idx / size, col: idx % size) }

        // Guard against the rare "quiet pattern" that scrambles back to a clear
        // board: nudge by one extra distinct press.
        if board.isCleared {
            if let extra = (0..<n).first(where: { !chosen.contains($0) }) {
                chosen.insert(extra)
                board.press(row: extra / size, col: extra % size)
            }
        }

        let solution = chosen.sorted().map { Cell(row: $0 / size, col: $0 % size) }
        return DailyPuzzle(id: "seed-\(seed)-m\(count)", size: size, board: board, solution: solution)
    }

    /// A fresh random opening at the given difficulty (continuous variety).
    public static func randomPuzzle(size: Int = 5, difficulty: Difficulty) -> DailyPuzzle {
        var system = SystemRandomNumberGenerator()
        let n = size * size
        let lo = max(1, min(difficulty.parRange.lowerBound, n))
        let hi = max(lo, min(difficulty.parRange.upperBound, n))
        let moveCount = Int.random(in: lo...hi, using: &system)
        return puzzle(seed: system.next(), size: size, moveCount: moveCount)
    }

    /// Build a puzzle directly from a day key (useful for tests and previews).
    public static func puzzle(forDayKey key: String, size: Int = 5) -> DailyPuzzle {
        var rng = SeededRNG(seed: stableSeed("gutenberglumen:\(key):\(size)"))

        // Press a random set of cells from a cleared board. The board stays
        // solvable by construction, and the parity-reduced press set is a
        // guaranteed solution (Lights Out presses are self-inverse & commute).
        var parity = [Bool](repeating: false, count: size * size)
        let budget = pressBudget(size: size, rng: &rng)
        for _ in 0..<budget {
            let r = Int.random(in: 0..<size, using: &rng)
            let c = Int.random(in: 0..<size, using: &rng)
            parity[r * size + c].toggle()
        }

        var solution = parityToCells(parity, size: size)

        // Guarantee a non-trivial puzzle: if everything cancelled out, force one.
        if solution.isEmpty {
            let r = Int.random(in: 0..<size, using: &rng)
            let c = Int.random(in: 0..<size, using: &rng)
            solution = [Cell(row: r, col: c)]
        }

        var board = Board(size: size)
        for cell in solution {
            board.press(row: cell.row, col: cell.col)
        }

        return DailyPuzzle(id: key, size: size, board: board, solution: solution)
    }

    private static func parityToCells(_ parity: [Bool], size: Int) -> [Cell] {
        var cells: [Cell] = []
        for r in 0..<size {
            for c in 0..<size where parity[r * size + c] {
                cells.append(Cell(row: r, col: c))
            }
        }
        return cells
    }
}
