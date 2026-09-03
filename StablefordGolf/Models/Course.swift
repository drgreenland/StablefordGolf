import Foundation

struct Course: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var holes: [Hole]
    var availableTees: [TeeColor]
}

struct Hole: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var number: Int
    var par: Int
    var strokeIndex: Int
    var teeDistances: [TeeDistance]
}

struct TeeDistance: Codable, Hashable {
    var teeId: UUID
    var distance: Int
}

struct TeeColor: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
}

// MARK: - Course mapper JSON import

struct CourseMapperJSON: Decodable {
    let name: String
    let holes: [HoleMapperJSON]

    struct HoleMapperJSON: Decodable {
        let number: Int
        let par: Int
        let strokeIndex: Int
        let tees: [TeeMapperJSON]?
    }

    struct TeeMapperJSON: Decodable {
        let name: String
        let distance: Int
    }

    func toCourse() -> Course {
        var teeColorMap: [String: TeeColor] = [:]
        for hole in holes {
            for tee in hole.tees ?? [] {
                if teeColorMap[tee.name] == nil {
                    teeColorMap[tee.name] = TeeColor(name: tee.name)
                }
            }
        }
        let availableTees = Array(teeColorMap.values).sorted { $0.name < $1.name }

        let courseHoles = holes.map { h -> Hole in
            let teeDistances = (h.tees ?? []).compactMap { t -> TeeDistance? in
                guard let tc = teeColorMap[t.name] else { return nil }
                return TeeDistance(teeId: tc.id, distance: t.distance)
            }
            return Hole(number: h.number, par: h.par, strokeIndex: h.strokeIndex, teeDistances: teeDistances)
        }.sorted { $0.number < $1.number }

        return Course(name: name, holes: courseHoles, availableTees: availableTees)
    }
}
