import SwiftUI

struct RoundHistoryView: View {
    @EnvironmentObject var dataManager: DataManager

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    var body: some View {
        List {
            ForEach(dataManager.rounds) { round in
                NavigationLink(value: RoundHistNavDest.summary(round)) {
                    RoundHistoryRow(round: round)
                }
            }
            .onDelete(perform: dataManager.deleteRound)
        }
        .scrollContentBackground(.hidden)
        .background { AppColors.grassGradient.ignoresSafeArea() }
        .navigationTitle("Round History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { EditButton() }
        }
        .overlay {
            if dataManager.rounds.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "flag.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Rounds Yet")
                        .font(.headline)
                    Text("Start a new round to see history here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationDestination(for: RoundHistNavDest.self) { dest in
            if case .summary(let round) = dest {
                RoundSummaryView(round: round)
            }
        }
    }
}

enum RoundHistNavDest: Hashable {
    case summary(Round)
}

struct RoundHistoryRow: View {
    let round: Round
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(round.course.name).font(.headline)
                Spacer()
                statusPill
            }
            Text(dateFormatter.string(from: round.date))
                .font(.caption).foregroundColor(.secondary)
            Text(round.matchStatusText)
                .font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var statusPill: some View {
        Text(round.status == .completed ? "Complete" : "In Progress")
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(round.status == .completed ? AppColors.fairwayGreen : .orange)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
