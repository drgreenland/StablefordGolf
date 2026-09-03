import Foundation

struct HolePoints: Identifiable, Codable {
    var id: UUID = UUID()
    var holeNumber: Int
    // String UUID keys to avoid Swift's alternating-array encoding bug for [UUID:Int]
    var playerPoints: [String: Int]   // UUID string → Stableford points (0-5)
    var playerStrokes: [String: Int]  // UUID string → raw strokes (0 = pick-up)
}
