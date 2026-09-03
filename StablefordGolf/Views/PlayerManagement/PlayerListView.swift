import SwiftUI

struct PlayerListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddPlayer = false

    var body: some View {
        List {
            ForEach(dataManager.players) { player in
                NavigationLink(value: PlayerNavDest.edit(player)) {
                    PlayerRow(player: player)
                }
            }
            .onDelete(perform: dataManager.deletePlayer)
        }
        .navigationTitle("Players")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddPlayer = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) { EditButton() }
        }
        .sheet(isPresented: $showingAddPlayer) {
            PlayerFormView(player: nil)
        }
        .navigationDestination(for: PlayerNavDest.self) { dest in
            if case .edit(let player) = dest {
                PlayerFormView(player: player)
            }
        }
    }
}

enum PlayerNavDest: Hashable {
    case edit(Player)
}

struct PlayerRow: View {
    let player: Player

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(player.name).font(.headline)
                Text("Handicap: \(player.handicap, specifier: "%.1f")").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}
