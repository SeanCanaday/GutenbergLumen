import XCTest
@testable import GutenbergLumenKit

final class BoardTests: XCTestCase {
    func testPressTogglesPlusShape() {
        var board = Board(size: 3)
        board.press(row: 1, col: 1)
        // Center + 4 neighbors lit = 5
        XCTAssertEqual(board.litCount, 5)
        XCTAssertTrue(board.isLit(row: 1, col: 1))
        XCTAssertTrue(board.isLit(row: 0, col: 1))
        XCTAssertTrue(board.isLit(row: 2, col: 1))
        XCTAssertTrue(board.isLit(row: 1, col: 0))
        XCTAssertTrue(board.isLit(row: 1, col: 2))
        // Corners untouched
        XCTAssertFalse(board.isLit(row: 0, col: 0))
    }

    func testCornerPressClipsToBounds() {
        var board = Board(size: 3)
        board.press(row: 0, col: 0)
        // self + right + down = 3
        XCTAssertEqual(board.litCount, 3)
    }

    func testPressIsSelfInverse() {
        var board = Board(size: 4)
        board.press(row: 2, col: 1)
        board.press(row: 2, col: 1)
        XCTAssertTrue(board.isCleared)
    }

    func testClearedStartState() {
        XCTAssertTrue(Board(size: 5).isCleared)
    }
}

final class DailyPuzzleTests: XCTestCase {
    func testDeterministicForSameKey() {
        let a = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-25", size: 5)
        let b = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-25", size: 5)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.board, b.board)
    }

    func testDifferentKeysDiffer() {
        let a = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-25", size: 5)
        let b = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-26", size: 5)
        XCTAssertNotEqual(a.board, b.board)
    }

    func testGeneratedPuzzleIsNonTrivial() {
        for day in 1...28 {
            let key = String(format: "2026-06-%02d", day)
            let puzzle = DailyPuzzleGenerator.puzzle(forDayKey: key, size: 5)
            XCTAssertFalse(puzzle.board.isCleared, "puzzle \(key) should not start solved")
            XCTAssertFalse(puzzle.solution.isEmpty)
        }
    }

    func testPatternsAreDistinctAndSolvable() {
        var boards: Set<[Bool]> = []
        for index in 0..<10 {
            let puzzle = DailyPuzzleGenerator.puzzle(patternIndex: index, size: 5)
            XCTAssertFalse(puzzle.board.isCleared, "pattern \(index) should not start solved")
            boards.insert(puzzle.board.cells)

            var board = puzzle.board
            for cell in puzzle.solution { board.press(row: cell.row, col: cell.col) }
            XCTAssertTrue(board.isCleared, "pattern \(index) must be solvable")
        }
        // Expect a healthy amount of variety across the 10 openings.
        XCTAssertGreaterThanOrEqual(boards.count, 8)
    }

    func testPatternIndexIsDeterministic() {
        let a = DailyPuzzleGenerator.puzzle(patternIndex: 3, size: 5)
        let b = DailyPuzzleGenerator.puzzle(patternIndex: 3, size: 5)
        XCTAssertEqual(a, b)
    }

    func testSeededPuzzleIsReproducible() {
        let a = DailyPuzzleGenerator.puzzle(seed: 123_456_789, size: 5)
        let b = DailyPuzzleGenerator.puzzle(seed: 123_456_789, size: 5)
        XCTAssertEqual(a, b)
    }

    func testDifficultyControlsParAndStaysSolvable() {
        for difficulty in Difficulty.allCases {
            for _ in 0..<20 {
                let puzzle = DailyPuzzleGenerator.randomPuzzle(size: 5, difficulty: difficulty)
                let par = puzzle.parMoves
                // Par should land within (or one above, due to the quiet-pattern
                // nudge) the difficulty's range.
                XCTAssertGreaterThanOrEqual(par, difficulty.parRange.lowerBound)
                XCTAssertLessThanOrEqual(par, difficulty.parRange.upperBound + 1)

                var board = puzzle.board
                for cell in puzzle.solution { board.press(row: cell.row, col: cell.col) }
                XCTAssertTrue(board.isCleared)
            }
        }
    }

    func testHarderIsGenerallyMoreMovesThanEasy() {
        func avgPar(_ d: Difficulty) -> Double {
            let pars = (0..<40).map { _ in
                Double(DailyPuzzleGenerator.randomPuzzle(size: 5, difficulty: d).parMoves)
            }
            return pars.reduce(0, +) / Double(pars.count)
        }
        XCTAssertLessThan(avgPar(.easy), avgPar(.medium))
        XCTAssertLessThan(avgPar(.medium), avgPar(.hard))
    }

    func testMoveCountPuzzleHasExactPar() {
        let puzzle = DailyPuzzleGenerator.puzzle(seed: 42, size: 5, moveCount: 9)
        XCTAssertEqual(puzzle.parMoves, 9)
    }

    func testRandomPuzzlesAreSolvableAndVaried() {
        var boards: Set<[Bool]> = []
        for _ in 0..<40 {
            let puzzle = DailyPuzzleGenerator.randomPuzzle(size: 5)
            XCTAssertFalse(puzzle.board.isCleared)
            var board = puzzle.board
            for cell in puzzle.solution { board.press(row: cell.row, col: cell.col) }
            XCTAssertTrue(board.isCleared, "every random puzzle must be solvable")
            boards.insert(puzzle.board.cells)
        }
        // With ~8M solvable 5x5 boards, 40 draws should almost never collide.
        XCTAssertGreaterThanOrEqual(boards.count, 35)
    }

    func testSolutionActuallyClearsBoard() {
        for day in 1...28 {
            let key = String(format: "2026-06-%02d", day)
            let puzzle = DailyPuzzleGenerator.puzzle(forDayKey: key, size: 5)
            var board = puzzle.board
            for cell in puzzle.solution {
                board.press(row: cell.row, col: cell.col)
            }
            XCTAssertTrue(board.isCleared, "solution for \(key) must clear the board")
        }
    }
}

final class PuzzleSessionTests: XCTestCase {
    func testSolvingViaSessionClearsAndCountsMoves() {
        let puzzle = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-25", size: 5)
        var session = PuzzleSession(puzzle: puzzle)
        XCTAssertFalse(session.isCleared)
        for cell in puzzle.solution {
            session.press(row: cell.row, col: cell.col)
        }
        XCTAssertTrue(session.isCleared)
        XCTAssertEqual(session.moves, puzzle.solution.count)
        XCTAssertEqual(session.overPar, 0)
    }

    func testPressIgnoredAfterCleared() {
        let puzzle = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-25", size: 5)
        var session = PuzzleSession(puzzle: puzzle)
        for cell in puzzle.solution {
            session.press(row: cell.row, col: cell.col)
        }
        let movesAfterWin = session.moves
        XCTAssertFalse(session.press(row: 0, col: 0))
        XCTAssertEqual(session.moves, movesAfterWin)
    }

    func testResetRestoresStart() {
        let puzzle = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-25", size: 5)
        var session = PuzzleSession(puzzle: puzzle)
        session.press(row: 0, col: 0)
        session.press(row: 1, col: 2)
        session.reset()
        XCTAssertEqual(session.board, puzzle.board)
        XCTAssertEqual(session.moves, 0)
        XCTAssertTrue(session.pressHistory.isEmpty)
    }

    func testHintLeadsToSolutionFromStart() {
        let puzzle = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-25", size: 5)
        var session = PuzzleSession(puzzle: puzzle)
        XCTAssertNotNil(session.hint)
        // Following hints repeatedly must always clear the board.
        var guardCount = 0
        while let hint = session.hint, guardCount < 100 {
            session.press(row: hint.row, col: hint.col)
            guardCount += 1
        }
        XCTAssertTrue(session.isCleared)
        XCTAssertNil(session.hint)
    }

    func testHintRecoversAfterWrongMove() {
        let puzzle = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-27", size: 5)
        var session = PuzzleSession(puzzle: puzzle)
        // Make an arbitrary (likely wrong) move first.
        session.press(row: 0, col: 0)
        // Hints recompute against the live board, so they still solve it.
        var guardCount = 0
        while let hint = session.hint, guardCount < 100 {
            session.press(row: hint.row, col: hint.col)
            guardCount += 1
        }
        XCTAssertTrue(session.isCleared)
    }

    func testHintNilWhenCleared() {
        let puzzle = DailyPuzzleGenerator.puzzle(forDayKey: "2026-06-25", size: 5)
        var session = PuzzleSession(puzzle: puzzle)
        for cell in puzzle.solution { session.press(row: cell.row, col: cell.col) }
        XCTAssertTrue(session.isCleared)
        XCTAssertNil(session.hint)
        XCTAssertTrue(session.remainingSolution.isEmpty)
    }
}
