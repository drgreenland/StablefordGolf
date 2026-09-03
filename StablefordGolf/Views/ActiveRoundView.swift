import SwiftUI

struct ActiveRoundView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State var round: Round

    // Stroke inputs for current hole: UUID string → strokes (0 = pick up)
    @State private var strokeInputs: [String: Int] = [:]
    @State private var pickedUp: Set<String> = []
    @State private var showingFinishAlert = false

    private var currentHoleData: Hole? {
        round.course.holes.first(where: { $0.number == round.currentHole })
    }

    private var allPlayers: [Player] { dataManager.players }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status banner
                statusBanner

                // Current hole card
                if let hole = currentHoleData {
                    holeCard(hole: hole)
                }

                // Submit / finish
                if round.status == .inProgress {
                    actionButtons
                }

                // Points summary so far
                if !round.holePoints.isEmpty {
                    pointsSummary
                }
            }
            .padding()
        }
        .navigationTitle("\(round.course.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if round.status == .inProgress {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") { showingFinishAlert = true }
                        .foregroundColor(.red)
                }
            }
        }
        .confirmationDialog("Finish Round?", isPresented: $showingFinishAlert, titleVisibility: .visible) {
            Button("Finish Round", role: .destructive) { finishRound() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will mark the round as complete.")
        }
        .onAppear { resetInputs() }
    }

    // MARK: - Sub-views

    private var statusBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hole \(round.currentHole) of \(round.course.holes.count)")
                    .font(.headline)
                Text(round.matchStatusText)
                    .font(.subheadline)
                    .foregroundColor(round.status == .completed ? AppColors.fairwayGreen : .secondary)
            }
            Spacer()
            if round.status == .completed {
                Text("COMPLETE")
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(AppColors.fairwayGreen)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private func holeCard(hole: Hole) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Hole \(hole.number)").font(.title2.bold())
                    Text("Par \(hole.par) · Stroke Index \(hole.strokeIndex)")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if let tee = round.tee,
                   let dist = hole.teeDistances.first(where: { $0.teeId == tee.id }) {
                    VStack(alignment: .trailing) {
                        Text("\(dist.distance)m").font(.title3.bold())
                        Text(tee.name).font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Player rows
            ForEach(round.players, id: \.self) { playerId in
                if let player = allPlayers.first(where: { $0.id == playerId }) {
                    playerScoreRow(player: player, hole: hole)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private func playerScoreRow(player: Player, hole: Hole) -> some View {
        let key = player.id.uuidString
        let hcpStrokes = round.strokesForHole(player: player, hole: hole, allPlayers: allPlayers)
        let strokes = strokeInputs[key] ?? 0
        let isPickedUp = pickedUp.contains(key)
        let pts = isPickedUp ? 0 : Round.stablefordPoints(strokes: strokes, par: hole.par, handicapStrokes: hcpStrokes)

        return VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name).font(.subheadline.bold())
                    HStack(spacing: 4) {
                        Text("HCP \(hcpStrokes > 0 ? "+\(hcpStrokes)" : "0")")
                            .font(.caption2).foregroundColor(.secondary)
                        if hcpStrokes > 0 {
                            Text("Net par \(hole.par - hcpStrokes)")
                                .font(.caption2).foregroundColor(AppColors.fairwayGreen)
                        }
                    }
                }
                Spacer()

                if round.status == .inProgress {
                    if isPickedUp {
                        Button("Un-pick") {
                            pickedUp.remove(key)
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    } else {
                        Stepper("\(strokes) stroke\(strokes == 1 ? "" : "s")",
                                value: Binding(
                                    get: { strokeInputs[key] ?? 0 },
                                    set: { strokeInputs[key] = $0 }
                                ),
                                in: 0...15)
                        .fixedSize()

                        // Pick up button (show when pts would be 0)
                        if pts == 0 && strokes > 0 {
                            Button("Pick Up") {
                                pickedUp.insert(key)
                                strokeInputs[key] = 0
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .foregroundColor(.orange)
                        }
                    }
                } else {
                    // Completed round — show stored points
                    let stored = round.holePoints
                        .first(where: { $0.holeNumber == hole.number })?
                        .playerPoints[key]
                    if let p = stored {
                        pointsBadge(p)
                    }
                }
            }

            // Points preview (in-progress)
            if round.status == .inProgress {
                HStack {
                    Spacer()
                    pointsBadge(pts)
                    Text(pointsLabel(pts))
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: submitHole) {
                Label("Submit Hole \(round.currentHole)", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.fairwayGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!allPlayersEntered)
        }
    }

    private var pointsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Running Total").font(.headline)
            if round.isTeamPlay {
                HStack {
                    Text("Team 1").font(.subheadline)
                    Spacer()
                    Text("\(round.teamTotal(team: 0)) pts").font(.headline).foregroundColor(AppColors.fairwayGreen)
                }
                HStack {
                    Text("Team 2").font(.subheadline)
                    Spacer()
                    Text("\(round.teamTotal(team: 1)) pts").font(.headline).foregroundColor(AppColors.skyBlue)
                }
            } else {
                ForEach(round.players, id: \.self) { pid in
                    if let player = allPlayers.first(where: { $0.id == pid }) {
                        HStack {
                            Text(player.name).font(.subheadline)
                            Spacer()
                            Text("\(round.totalPoints(for: pid)) pts").font(.headline).foregroundColor(AppColors.fairwayGreen)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    // MARK: - Logic

    private var allPlayersEntered: Bool {
        round.players.allSatisfy { pid in
            let key = pid.uuidString
            return pickedUp.contains(key) || (strokeInputs[key] ?? 0) > 0
        }
    }

    private func resetInputs() {
        strokeInputs = [:]
        pickedUp = []
    }

    private func submitHole() {
        guard let hole = currentHoleData, allPlayersEntered else { return }

        var playerPoints: [String: Int] = [:]
        var playerStrokes: [String: Int] = [:]

        for pid in round.players {
            let key = pid.uuidString
            let isPickedUp = pickedUp.contains(key)
            let strokes = isPickedUp ? 0 : (strokeInputs[key] ?? 0)
            let hcpStrokes = allPlayers.first(where: { $0.id == pid }).map {
                round.strokesForHole(player: $0, hole: hole, allPlayers: allPlayers)
            } ?? 0
            let pts = isPickedUp ? 0 : Round.stablefordPoints(strokes: strokes, par: hole.par, handicapStrokes: hcpStrokes)
            playerPoints[key] = pts
            playerStrokes[key] = strokes
        }

        let hp = HolePoints(holeNumber: round.currentHole, playerPoints: playerPoints, playerStrokes: playerStrokes)

        // Remove any existing entry for this hole (in case of re-entry)
        round.holePoints.removeAll { $0.holeNumber == round.currentHole }
        round.holePoints.append(hp)
        round.holePoints.sort { $0.holeNumber < $1.holeNumber }

        let totalHoles = round.course.holes.count
        if round.currentHole < totalHoles {
            round.currentHole += 1
        } else {
            round.status = .completed
        }

        dataManager.updateRound(round)
        resetInputs()
    }

    private func finishRound() {
        round.status = .completed
        dataManager.updateRound(round)
    }

    private func pointsBadge(_ pts: Int) -> some View {
        Text("\(pts)")
            .font(.headline.bold())
            .frame(width: 32, height: 32)
            .background(badgeColor(pts))
            .foregroundColor(.white)
            .clipShape(Circle())
    }

    private func badgeColor(_ pts: Int) -> Color {
        switch pts {
        case 0: return .gray
        case 1: return .red
        case 2: return .blue
        case 3: return AppColors.fairwayGreen
        case 4: return .yellow
        default: return .orange  // 5+ (albatross)
        }
    }

    private func pointsLabel(_ pts: Int) -> String {
        switch pts {
        case 0: return "No score"
        case 1: return "Bogey"
        case 2: return "Par"
        case 3: return "Birdie"
        case 4: return "Eagle"
        case 5: return "Albatross"
        default: return "\(pts) pts"
        }
    }
}
