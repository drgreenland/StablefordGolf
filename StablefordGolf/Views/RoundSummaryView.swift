import SwiftUI

struct RoundSummaryView: View {
    let round: Round
    @EnvironmentObject var dataManager: DataManager

    private var allPlayers: [Player] { dataManager.players }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Final result
                resultCard

                // Hole-by-hole table
                scorecardTable
            }
            .padding()
        }
        .navigationTitle(round.course.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Result card
    private var resultCard: some View {
        VStack(spacing: 8) {
            Text(round.matchStatusText)
                .font(.title3.bold())
                .foregroundColor(AppColors.fairwayGreen)

            Divider()

            if round.isTeamPlay {
                HStack(spacing: 24) {
                    teamTotalView(team: 0, label: "Team 1")
                    teamTotalView(team: 1, label: "Team 2")
                }
            } else {
                HStack(spacing: 24) {
                    ForEach(round.players, id: \.self) { pid in
                        if let player = allPlayers.first(where: { $0.id == pid }) {
                            VStack {
                                Text(player.name).font(.caption)
                                Text("\(round.totalPoints(for: pid))")
                                    .font(.title2.bold())
                                    .foregroundColor(AppColors.fairwayGreen)
                                Text("pts").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private func teamTotalView(team: Int, label: String) -> some View {
        VStack {
            Text(label).font(.caption)
            Text("\(round.teamTotal(team: team))")
                .font(.title2.bold())
                .foregroundColor(team == 0 ? AppColors.fairwayGreen : AppColors.skyBlue)
            Text("pts").font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: - Scorecard table
    private var scorecardTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("Hole").frame(width: 44, alignment: .leading).font(.caption.bold())
                Text("Par").frame(width: 36, alignment: .center).font(.caption.bold())
                ForEach(round.players, id: \.self) { pid in
                    Text(displayName(pid))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.caption.bold())
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(AppColors.fairwayGreen.opacity(0.15))

            Divider()

            // Hole rows
            ForEach(round.holePoints.sorted(by: { $0.holeNumber < $1.holeNumber })) { hp in
                let hole = round.course.holes.first(where: { $0.number == hp.holeNumber })
                HStack(spacing: 0) {
                    Text("\(hp.holeNumber)").frame(width: 44, alignment: .leading).font(.caption)
                    Text("\(hole?.par ?? 0)").frame(width: 36, alignment: .center).font(.caption).foregroundColor(.secondary)
                    ForEach(round.players, id: \.self) { pid in
                        let pts = hp.playerPoints[pid.uuidString] ?? 0
                        pointsCell(pts)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                Divider()
            }

            // Totals row
            HStack(spacing: 0) {
                Text("Total").frame(width: 44, alignment: .leading).font(.caption.bold())
                Text("").frame(width: 36)
                ForEach(round.players, id: \.self) { pid in
                    Text("\(round.totalPoints(for: pid))")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.caption.bold())
                        .foregroundColor(AppColors.fairwayGreen)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(AppColors.fairwayGreen.opacity(0.08))
        }
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private func pointsCell(_ pts: Int) -> some View {
        Text("\(pts)")
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.caption)
            .foregroundColor(pointsColor(pts))
    }

    private func pointsColor(_ pts: Int) -> Color {
        switch pts {
        case 0: return .gray
        case 1: return .red
        case 2: return .primary
        case 3: return AppColors.fairwayGreen
        default: return .orange
        }
    }

    private func displayName(_ pid: UUID) -> String {
        guard let idx = round.players.firstIndex(of: pid), idx < round.playerDisplayNames.count else {
            return allPlayers.first(where: { $0.id == pid })?.name ?? "Player"
        }
        return round.playerDisplayNames[idx]
    }
}
