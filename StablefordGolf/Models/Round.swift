import Foundation

struct Round: Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var course: Course
    var tee: TeeColor?
    var players: [UUID]
    var teams: [Int]
    var isTeamPlay: Bool
    var currentHole: Int = 1
    var status: RoundStatus = .inProgress
    var holePoints: [HolePoints] = []
    var playerDisplayNames: [String] = []

    enum CodingKeys: String, CodingKey {
        case id, date, course, tee, players, teams, isTeamPlay, currentHole, status, holePoints, playerDisplayNames
    }
}

enum RoundStatus: String, Codable {
    case inProgress
    case completed
}

// MARK: - Codable (backward-compatible playerDisplayNames)
extension Round: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        course = try c.decode(Course.self, forKey: .course)
        tee = try c.decodeIfPresent(TeeColor.self, forKey: .tee)
        players = try c.decode([UUID].self, forKey: .players)
        teams = try c.decode([Int].self, forKey: .teams)
        isTeamPlay = try c.decode(Bool.self, forKey: .isTeamPlay)
        currentHole = try c.decode(Int.self, forKey: .currentHole)
        status = try c.decode(RoundStatus.self, forKey: .status)
        holePoints = try c.decode([HolePoints].self, forKey: .holePoints)
        playerDisplayNames = (try? c.decode([String].self, forKey: .playerDisplayNames)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(course, forKey: .course)
        try c.encodeIfPresent(tee, forKey: .tee)
        try c.encode(players, forKey: .players)
        try c.encode(teams, forKey: .teams)
        try c.encode(isTeamPlay, forKey: .isTeamPlay)
        try c.encode(currentHole, forKey: .currentHole)
        try c.encode(status, forKey: .status)
        try c.encode(holePoints, forKey: .holePoints)
        try c.encode(playerDisplayNames, forKey: .playerDisplayNames)
    }
}

// MARK: - Scoring
extension Round {
    static func stablefordPoints(strokes: Int, par: Int, handicapStrokes: Int) -> Int {
        guard strokes > 0 else { return 0 }  // 0 = picked up
        let net = strokes - handicapStrokes
        return max(0, 2 - (net - par))
    }

    func strokesForHole(player: Player, hole: Hole, allPlayers: [Player]) -> Int {
        guard let playerIdx = players.firstIndex(of: player.id) else { return 0 }
        let team = teams[playerIdx]
        let opponentIds = players.enumerated().filter { teams[$0.offset] != team }.map { $0.element }
        let lowestOpponentHcp = allPlayers.filter { opponentIds.contains($0.id) }.map(\.handicap).min() ?? 0
        let diff = Int(round(player.handicap - lowestOpponentHcp))
        guard diff > 0 else { return 0 }
        var s = 0
        if hole.strokeIndex <= min(diff, 18) { s += 1 }
        if diff > 18 && hole.strokeIndex <= min(diff - 18, 18) { s += 1 }
        if diff > 36 && hole.strokeIndex <= (diff - 36) { s += 1 }
        return s
    }

    func totalPoints(for playerId: UUID) -> Int {
        holePoints.compactMap { $0.playerPoints[playerId.uuidString] }.reduce(0, +)
    }

    func teamTotal(team: Int) -> Int {
        let teamIds = players.enumerated().filter { teams[$0.offset] == team }.map { $0.element }
        return holePoints.reduce(0) { sum, hp in
            let best = teamIds.compactMap { hp.playerPoints[$0.uuidString] }.max() ?? 0
            return sum + best
        }
    }

    var matchStatusText: String {
        guard !holePoints.isEmpty else { return "Hole 1" }

        if isTeamPlay {
            let t0 = teamTotal(team: 0)
            let t1 = teamTotal(team: 1)
            if status == .completed {
                if t0 > t1 { return "Team 1 wins \(t0)–\(t1)" }
                if t1 > t0 { return "Team 2 wins \(t1)–\(t0)" }
                return "Tied \(t0)–\(t1)"
            }
            let diff = t0 - t1
            if diff == 0 { return "Tied" }
            return "\(diff > 0 ? "Team 1" : "Team 2") leads by \(abs(diff)) pts"
        } else {
            guard let p0id = players.enumerated().first(where: { teams[$0.offset] == 0 })?.element,
                  let p1id = players.enumerated().first(where: { teams[$0.offset] == 1 })?.element else { return "" }
            let p0pts = totalPoints(for: p0id)
            let p1pts = totalPoints(for: p1id)
            let p0name = displayName(for: p0id)
            let p1name = displayName(for: p1id)
            if status == .completed {
                if p0pts > p1pts { return "\(p0name) wins \(p0pts)–\(p1pts)" }
                if p1pts > p0pts { return "\(p1name) wins \(p1pts)–\(p0pts)" }
                return "Tied \(p0pts)–\(p1pts)"
            }
            let diff = p0pts - p1pts
            if diff == 0 { return "Tied" }
            return "\(diff > 0 ? p0name : p1name) leads by \(abs(diff)) pts"
        }
    }

    private func displayName(for playerId: UUID) -> String {
        guard let idx = players.firstIndex(of: playerId), idx < playerDisplayNames.count else { return "Player" }
        return playerDisplayNames[idx]
    }
}
