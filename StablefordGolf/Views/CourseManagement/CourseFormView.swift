import SwiftUI

struct CourseFormView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let course: Course?
    private var isNew: Bool { course == nil }

    @State private var name: String = ""
    @State private var holes: [Hole] = []
    @State private var tees: [TeeColor] = []
    @State private var showingAddTee = false
    @State private var editingHole: Hole? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Course Name") {
                    TextField("Name", text: $name)
                }

                Section("Tee Colours") {
                    ForEach(tees) { tee in
                        Text(tee.name)
                    }
                    .onDelete { idx in tees.remove(atOffsets: idx) }
                    Button("Add Tee") { showingAddTee = true }
                }

                Section("Holes (\(holes.count))") {
                    ForEach(holes) { hole in
                        Button {
                            editingHole = hole
                        } label: {
                            HoleRow(hole: hole, tees: tees)
                        }
                        .foregroundColor(.primary)
                    }
                    if holes.count < 18 {
                        Button("Add Hole") { addHole() }
                    }
                }
            }
            .navigationTitle(isNew ? "New Course" : "Edit Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || holes.isEmpty)
                }
            }
            .onAppear { loadExisting() }
            .sheet(isPresented: $showingAddTee) {
                TeeColorFormView { newTee in
                    tees.append(newTee)
                }
            }
            .sheet(item: $editingHole) { hole in
                HoleFormView(hole: hole, tees: tees) { updated in
                    if let idx = holes.firstIndex(where: { $0.id == updated.id }) {
                        holes[idx] = updated
                    }
                }
            }
        }
    }

    private func loadExisting() {
        guard let c = course else {
            // Default 18 holes
            holes = (1...18).map { Hole(number: $0, par: 4, strokeIndex: $0, teeDistances: []) }
            return
        }
        name = c.name; holes = c.holes; tees = c.availableTees
    }

    private func addHole() {
        let next = (holes.map(\.number).max() ?? 0) + 1
        holes.append(Hole(number: next, par: 4, strokeIndex: next, teeDistances: []))
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var c = course ?? Course(name: trimmed, holes: [], availableTees: [])
        c.name = trimmed; c.holes = holes; c.availableTees = tees
        if isNew { dataManager.addCourse(c) } else { dataManager.updateCourse(c) }
        dismiss()
    }
}

struct HoleRow: View {
    let hole: Hole
    let tees: [TeeColor]

    var body: some View {
        HStack {
            Text("Hole \(hole.number)")
            Spacer()
            Text("Par \(hole.par) · SI \(hole.strokeIndex)")
                .font(.caption).foregroundColor(.secondary)
        }
    }
}
