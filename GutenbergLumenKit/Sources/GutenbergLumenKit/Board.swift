import Foundation

/// A single grid position.
public struct Cell: Equatable, Hashable, Sendable {
    public let row: Int
    public let col: Int
    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

/// A square Lights Out board. A cell is `true` when lit; the goal is to clear
/// every cell. Pressing a cell toggles it and its orthogonal neighbors.
public struct Board: Equatable, Sendable {
    public let size: Int
    public private(set) var cells: [Bool]

    public init(size: Int, lit: Bool = false) {
        precondition(size > 0, "board size must be positive")
        self.size = size
        self.cells = Array(repeating: lit, count: size * size)
    }

    public init(size: Int, cells: [Bool]) {
        precondition(size > 0, "board size must be positive")
        precondition(cells.count == size * size, "cells count must equal size*size")
        self.size = size
        self.cells = cells
    }

    public func contains(row: Int, col: Int) -> Bool {
        row >= 0 && row < size && col >= 0 && col < size
    }

    private func index(_ row: Int, _ col: Int) -> Int { row * size + col }

    public func isLit(row: Int, col: Int) -> Bool {
        cells[index(row, col)]
    }

    public var litCount: Int { cells.lazy.filter { $0 }.count }

    /// True when no cell is lit — the win condition.
    public var isCleared: Bool { !cells.contains(true) }

    /// Flip a single cell (no neighbor effect). Internal helper.
    private mutating func flip(_ row: Int, _ col: Int) {
        guard contains(row: row, col: col) else { return }
        cells[index(row, col)].toggle()
    }

    /// Press a cell: toggles it and its up/down/left/right neighbors.
    public mutating func press(row: Int, col: Int) {
        guard contains(row: row, col: col) else { return }
        flip(row, col)
        flip(row - 1, col)
        flip(row + 1, col)
        flip(row, col - 1)
        flip(row, col + 1)
    }

    public func pressed(row: Int, col: Int) -> Board {
        var copy = self
        copy.press(row: row, col: col)
        return copy
    }
}
