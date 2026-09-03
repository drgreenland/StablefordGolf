import SwiftUI

struct TeeColorFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    let onSave: (TeeColor) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Tee Name") {
                    TextField("e.g. Blue, Red, White", text: $name)
                }
            }
            .navigationTitle("Add Tee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { onSave(TeeColor(name: name)); dismiss() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
