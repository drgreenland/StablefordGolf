import SwiftUI

struct PlayerListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddPlayer = false
    @State private var editingPlayer: Player? = nil

    var body: some View {
        List {
            ForEach(dataManager.players) { player in
                Button {
                    editingPlayer = player
                } label: {
                    PlayerRow(player: player)
                }
                .foregroundColor(.primary)
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
        .sheet(item: $editingPlayer) { player in
            PlayerFormView(player: player)
        }
    }
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
