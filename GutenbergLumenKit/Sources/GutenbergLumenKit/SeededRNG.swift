import Foundation

/// Deterministic, cross-platform PRNG (SplitMix64).
///
/// Swift's built-in `Hasher`/`SystemRandomNumberGenerator` are seeded
/// per-process, so they can't produce a stable "daily" puzzle. This does.
public struct SeededRNG: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        // Avoid a zero state producing a degenerate stream.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Stable 64-bit FNV-1a hash of a string. Unlike `String.hashValue`, this is
/// identical across processes, runs, and platforms — so a date key always maps
/// to the same puzzle.
public func stableSeed(_ string: String) -> UInt64 {
    var hash: UInt64 = 0xCBF29CE484222325
    for byte in string.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* 0x0000_0100_0000_01B3
    }
    return hash
}
