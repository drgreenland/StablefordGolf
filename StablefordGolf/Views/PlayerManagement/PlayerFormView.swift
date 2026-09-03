import SwiftUI

struct PlayerFormView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let player: Player?  // nil = new player

    @State private var name: String = ""
    @State private var handicap: Double = 18.0

    private var isNew: Bool { player == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Details") {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Handicap")
                        Spacer()
                        TextField("0.0", value: $handicap, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { AppColors.grassGradient.ignoresSafeArea() }
            .navigationTitle(isNew ? "New Player" : "Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let p = player { name = p.name; handicap = p.handicap }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if var existing = player {
            existing.name = trimmed
            existing.handicap = handicap
            dataManager.updatePlayer(existing)
        } else {
            dataManager.addPlayer(Player(name: trimmed, handicap: handicap))
        }
        dismiss()
    }
}
