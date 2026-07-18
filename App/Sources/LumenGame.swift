import Foundation
import Observation
import GutenbergLumenKit

/// Session controller: puzzle play, hints, streak / best persistence.
@MainActor
@Observable
final class LumenGame {
    private(set) var session: PuzzleSession
    private let size: Int

    private(set) var difficulty: Difficulty
    private(set) var streak: Int
    private(set) var hintCell: Cell?
    private(set) var hintsUsed: Int = 0
    private(set) var didJustWin: Bool = false

    private let defaults = UserDefaults.standard
    private let streakKey = "gutenberglumen.streak"
    private let lastSolvedKey = "gutenberglumen.lastSolved"
    private let bestMovesPrefix = "gutenberglumen.best."
    private let difficultyKey = "gutenberglumen.difficulty"

    init(size: Int = 5) {
        self.size = size
        let saved = UserDefaults.standard.string(forKey: difficultyKey)
        let startDifficulty = saved.flatMap(Difficulty.init(rawValue:)) ?? .medium
        self.difficulty = startDifficulty
        self.session = PuzzleSession(
            puzzle: DailyPuzzleGenerator.randomPuzzle(size: size, difficulty: startDifficulty)
        )
        self.streak = UserDefaults.standard.integer(forKey: streakKey)
    }

    var puzzleID: String { session.puzzle.id }
    var board: Board { session.board }
    var boardSize: Int { session.puzzle.size }
    var moves: Int { session.moves }
    var par: Int { session.parMoves }
    var litCount: Int { session.litCount }
    var isCleared: Bool { session.isCleared }

    var bestMoves: Int? {
        let value = defaults.integer(forKey: bestMovesPrefix + puzzleID)
        return value == 0 ? nil : value
    }

    func press(row: Int, col: Int) {
        guard !session.isCleared else { return }
        hintCell = nil
        session.press(row: row, col: col)
        if session.isCleared { recordWin() }
    }

    func requestHint() {
        guard !session.isCleared else { return }
        if hintCell == nil { hintsUsed += 1 }
        hintCell = session.hint
    }

    func reset() {
        session.reset()
        clearTransientState()
    }

    func newGame() {
        session = PuzzleSession(
            puzzle: DailyPuzzleGenerator.randomPuzzle(size: size, difficulty: difficulty)
        )
        clearTransientState()
    }

    func setDifficulty(_ newValue: Difficulty) {
        guard newValue != difficulty else { return }
        difficulty = newValue
        defaults.set(newValue.rawValue, forKey: difficultyKey)
        newGame()
    }

    private func clearTransientState() {
        hintCell = nil
        hintsUsed = 0
        didJustWin = false
    }

    private func recordWin() {
        didJustWin = true
        hintCell = nil

        let key = bestMovesPrefix + puzzleID
        let previousBest = defaults.integer(forKey: key)
        if previousBest == 0 || session.moves < previousBest {
            defaults.set(session.moves, forKey: key)
        }

        if defaults.string(forKey: lastSolvedKey) != puzzleID {
            streak += 1
            defaults.set(streak, forKey: streakKey)
            defaults.set(puzzleID, forKey: lastSolvedKey)
        }
    }
}
