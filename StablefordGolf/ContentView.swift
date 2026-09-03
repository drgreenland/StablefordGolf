import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.grassGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // App title
                        VStack(spacing: 4) {
                            Image(systemName: "flag.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            Text("Stableford Golf")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        // Active rounds
                        let activeRounds = dataManager.rounds.filter { $0.status == .inProgress }
                        if !activeRounds.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Active Rounds")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)

                                ForEach(activeRounds) { round in
                                    NavigationLink(value: NavigationDestination.activeRound(round)) {
                                        ActiveRoundBanner(round: round)
                                    }
                                }
                            }
                        }

                        // Main actions
                        VStack(spacing: 12) {
                            NavigationLink(value: NavigationDestination.newRound) {
                                MenuButton(title: "New Round", icon: "plus.circle.fill", color: AppColors.fairwayGreen)
                            }
                            NavigationLink(value: NavigationDestination.history) {
                                MenuButton(title: "Round History", icon: "clock.fill", color: AppColors.skyBlue)
                            }
                        }
                        .padding(.horizontal)

                        // Management
                        VStack(spacing: 12) {
                            NavigationLink(value: NavigationDestination.players) {
                                MenuButton(title: "Players", icon: "person.2.fill", color: .purple)
                            }
                            NavigationLink(value: NavigationDestination.courses) {
                                MenuButton(title: "Courses", icon: "map.fill", color: .orange)
                            }
                            NavigationLink(value: NavigationDestination.settings) {
                                MenuButton(title: "Settings", icon: "gearshape.fill", color: .gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: NavigationDestination.self) { dest in
                switch dest {
                case .newRound:
                    NewRoundView()
                case .history:
                    RoundHistoryView()
                case .players:
                    PlayerListView()
                case .courses:
                    CourseListView()
                case .settings:
                    SettingsView()
                case .activeRound(let round):
                    ActiveRoundView(round: round)
                }
            }
        }
    }
}

// MARK: - Navigation destination enum
enum NavigationDestination: Hashable {
    case newRound
    case history
    case players
    case courses
    case settings
    case activeRound(Round)
}

extension Round: Hashable {
    static func == (lhs: Round, rhs: Round) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Subviews
struct ActiveRoundBanner: View {
    let round: Round

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(round.course.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text("Hole \(round.currentHole) · \(round.matchStatusText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    ContentView().environmentObject(DataManager.shared)
}
