import Foundation

/// Live, mutable state for a play session over a `DailyPuzzle`. UI-agnostic so
/// it can be unit-tested headlessly and reused across tvOS / macOS / iOS.
public struct PuzzleSession: Sendable {
    public let puzzle: DailyPuzzle
    public private(set) var board: Board
    public private(set) var moves: Int
    public private(set) var pressHistory: [Cell]

    public init(puzzle: DailyPuzzle) {
        self.puzzle = puzzle
        self.board = puzzle.board
        self.moves = 0
        self.pressHistory = []
    }

    public var isCleared: Bool { board.isCleared }
    public var litCount: Int { board.litCount }
    public var parMoves: Int { puzzle.parMoves }

    /// The presses still required to clear the board from the *current* state,
    /// in stable row-major order. Because Lights Out presses are self-inverse
    /// and commute, this is just the symmetric difference of the puzzle's known
    /// solution and the presses made so far — so it stays correct even after
    /// wrong or redundant moves.
    public var remainingSolution: [Cell] {
        let n = puzzle.size
        var parity = [Bool](repeating: false, count: n * n)
        for cell in puzzle.solution { parity[cell.row * n + cell.col].toggle() }
        for cell in pressHistory { parity[cell.row * n + cell.col].toggle() }

        var cells: [Cell] = []
        for r in 0..<n {
            for c in 0..<n where parity[r * n + c] {
                cells.append(Cell(row: r, col: c))
            }
        }
        return cells
    }

    /// A single suggested next move toward solving, or `nil` if the board is
    /// already cleared.
    public var hint: Cell? { remainingSolution.first }

    /// Net result vs. par; <= 0 means at or under the known solution length.
    public var overPar: Int { moves - puzzle.parMoves }

    @discardableResult
    public mutating func press(row: Int, col: Int) -> Bool {
        guard board.contains(row: row, col: col), !isCleared else { return false }
        board.press(row: row, col: col)
        moves += 1
        pressHistory.append(Cell(row: row, col: col))
        return true
    }

    public mutating func reset() {
        board = puzzle.board
        moves = 0
        pressHistory.removeAll(keepingCapacity: true)
    }
}
