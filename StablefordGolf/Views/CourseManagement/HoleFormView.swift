import SwiftUI

struct HoleFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State var hole: Hole
    let tees: [TeeColor]
    let onSave: (Hole) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Hole \(hole.number)") {
                    Stepper("Par: \(hole.par)", value: $hole.par, in: 3...5)
                    Stepper("Stroke Index: \(hole.strokeIndex)", value: $hole.strokeIndex, in: 1...18)
                }

                Section("Tee Distances") {
                    ForEach(tees) { tee in
                        HStack {
                            Text(tee.name)
                            Spacer()
                            let binding = distanceBinding(for: tee)
                            TextField("0", value: binding, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text("m").foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Hole \(hole.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { onSave(hole); dismiss() } }
            }
        }
    }

    private func distanceBinding(for tee: TeeColor) -> Binding<Int> {
        Binding(
            get: { hole.teeDistances.first(where: { $0.teeId == tee.id })?.distance ?? 0 },
            set: { val in
                if let idx = hole.teeDistances.firstIndex(where: { $0.teeId == tee.id }) {
                    hole.teeDistances[idx].distance = val
                } else {
                    hole.teeDistances.append(TeeDistance(teeId: tee.id, distance: val))
                }
            }
        )
    }
}
