import Foundation
import Combine
import SwiftUI

struct AppData: Codable {
    let players: [Player]
    let courses: [Course]
    let rounds: [Round]
}

class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var players: [Player] = []
    @Published var courses: [Course] = []
    @Published var rounds: [Round] = []

    private init() { loadAll() }

    func loadAll() {
        let decoder = JSONDecoder()
        players = (try? decoder.decode([Player].self, from: UserDefaults.standard.data(forKey: "sg_players") ?? Data())) ?? []
        courses = (try? decoder.decode([Course].self, from: UserDefaults.standard.data(forKey: "sg_courses") ?? Data())) ?? []
        rounds  = (try? decoder.decode([Round].self,  from: UserDefaults.standard.data(forKey: "sg_rounds")  ?? Data())) ?? []
    }

    func savePlayers() { UserDefaults.standard.set(try? JSONEncoder().encode(players), forKey: "sg_players") }
    func saveCourses() { UserDefaults.standard.set(try? JSONEncoder().encode(courses), forKey: "sg_courses") }
    func saveRounds()  { UserDefaults.standard.set(try? JSONEncoder().encode(rounds),  forKey: "sg_rounds")  }

    // MARK: - Player CRUD
    func addPlayer(_ player: Player) { players.append(player); savePlayers() }
    func updatePlayer(_ player: Player) {
        if let idx = players.firstIndex(where: { $0.id == player.id }) { players[idx] = player; savePlayers() }
    }
    func deletePlayer(at offsets: IndexSet) { players.remove(atOffsets: offsets); savePlayers() }

    // MARK: - Course CRUD
    func addCourse(_ course: Course) { courses.append(course); saveCourses() }
    func updateCourse(_ course: Course) {
        if let idx = courses.firstIndex(where: { $0.id == course.id }) { courses[idx] = course; saveCourses() }
    }
    func deleteCourse(at offsets: IndexSet) { courses.remove(atOffsets: offsets); saveCourses() }

    // MARK: - Round CRUD
    func addRound(_ round: Round) { rounds.insert(round, at: 0); saveRounds() }
    func updateRound(_ round: Round) {
        if let idx = rounds.firstIndex(where: { $0.id == round.id }) { rounds[idx] = round; saveRounds() }
    }
    func deleteRound(at offsets: IndexSet) { rounds.remove(atOffsets: offsets); saveRounds() }

    // MARK: - Export / Import
    func exportData() throws -> Data {
        try JSONEncoder().encode(AppData(players: players, courses: courses, rounds: rounds))
    }

    func importData(_ data: Data) throws {
        let decoded = try JSONDecoder().decode(AppData.self, from: data)
        for p in decoded.players where !players.contains(where: { $0.id == p.id }) { players.append(p) }
        for c in decoded.courses where !courses.contains(where: { $0.id == c.id }) { courses.append(c) }
        for r in decoded.rounds {
            let exists = rounds.contains(where: {
                abs($0.date.timeIntervalSince(r.date)) < 60 && $0.course.name == r.course.name
            })
            if !exists { rounds.append(r) }
        }
        rounds.sort { $0.date > $1.date }
        savePlayers(); saveCourses(); saveRounds()
    }

    func importCourse(from data: Data) throws {
        let mapper = try JSONDecoder().decode(CourseMapperJSON.self, from: data)
        let course = mapper.toCourse()
        if !courses.contains(where: { $0.name == course.name }) {
            courses.append(course)
            saveCourses()
        }
    }

    func clearAllData() {
        players = []; courses = []; rounds = []
        savePlayers(); saveCourses(); saveRounds()
    }
}
