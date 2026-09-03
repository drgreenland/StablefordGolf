import SwiftUI

struct NewRoundView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlayerIds: [UUID] = []
    @State private var selectedCourse: Course? = nil
    @State private var selectedTee: TeeColor? = nil
    @State private var isTeamPlay = false
    @State private var teamAssignments: [UUID: Int] = [:]  // player id → team (0 or 1)

    var body: some View {
        Form {
                // Players section
                Section("Players (2–4)") {
                    ForEach(dataManager.players) { player in
                        let isSelected = selectedPlayerIds.contains(player.id)
                        Button {
                            togglePlayer(player)
                        } label: {
                            HStack {
                                Text(player.name)
                                Spacer()
                                Text("HCP \(player.handicap, specifier: "%.1f")")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.fairwayGreen)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    if dataManager.players.isEmpty {
                        Text("No players yet — add players first")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                // Course section
                Section("Course") {
                    if dataManager.courses.isEmpty {
                        Text("No courses yet — add a course first")
                            .foregroundColor(.secondary).italic()
                    } else {
                        Picker("Select Course", selection: $selectedCourse) {
                            Text("Choose…").tag(Optional<Course>.none)
                            ForEach(dataManager.courses) { course in
                                Text(course.name).tag(Optional(course))
                            }
                        }
                        if let course = selectedCourse, !course.availableTees.isEmpty {
                            Picker("Tee", selection: $selectedTee) {
                                Text("Choose…").tag(Optional<TeeColor>.none)
                                ForEach(course.availableTees) { tee in
                                    Text(tee.name).tag(Optional(tee))
                                }
                            }
                        }
                    }
                }

                // Format section (only if 3 or 4 players)
                if selectedPlayerIds.count >= 3 {
                    Section("Format") {
                        Toggle("Team Play (Better Ball)", isOn: $isTeamPlay)

                        if isTeamPlay && selectedPlayerIds.count == 4 {
                            Text("Team assignments:")
                                .font(.caption).foregroundColor(.secondary)
                            ForEach(Array(selectedPlayerIds.enumerated()), id: \.element) { idx, pid in
                                if let player = dataManager.players.first(where: { $0.id == pid }) {
                                    HStack {
                                        Text(player.name)
                                        Spacer()
                                        Picker("", selection: teamBinding(for: pid)) {
                                            Text("Team 1").tag(0)
                                            Text("Team 2").tag(1)
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(width: 140)
                                    }
                                }
                            }
                        }
                    }
                }
        }
        .navigationTitle("New Round")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Start") { startRound() }
                    .disabled(!canStart)
            }
        }
    }

    private var canStart: Bool {
        selectedPlayerIds.count >= 2 && selectedCourse != nil
    }

    private func togglePlayer(_ player: Player) {
        if let idx = selectedPlayerIds.firstIndex(of: player.id) {
            selectedPlayerIds.remove(at: idx)
            teamAssignments.removeValue(forKey: player.id)
        } else if selectedPlayerIds.count < 4 {
            selectedPlayerIds.append(player.id)
            // Default: alternating teams (singles = 0,1; team = 0,0,1,1)
            teamAssignments[player.id] = selectedPlayerIds.count % 2 == 1 ? 0 : 1
        }
    }

    private func teamBinding(for playerId: UUID) -> Binding<Int> {
        Binding(
            get: { teamAssignments[playerId] ?? 0 },
            set: { teamAssignments[playerId] = $0 }
        )
    }

    private func startRound() {
        guard let course = selectedCourse, selectedPlayerIds.count >= 2 else { return }

        let teams = selectedPlayerIds.map { pid -> Int in
            if isTeamPlay { return teamAssignments[pid] ?? 0 }
            // Singles: alternating 0,1,0,1
            return selectedPlayerIds.firstIndex(of: pid)! % 2
        }

        let displayNames = selectedPlayerIds.compactMap { pid in
            dataManager.players.first(where: { $0.id == pid })?.name
        }

        let round = Round(
            course: course,
            tee: selectedTee,
            players: selectedPlayerIds,
            teams: teams,
            isTeamPlay: isTeamPlay && selectedPlayerIds.count >= 3,
            playerDisplayNames: displayNames
        )

        dataManager.addRound(round)
        dismiss()
    }
}
