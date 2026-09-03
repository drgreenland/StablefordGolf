import SwiftUI

struct TeeColorFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var courseRating: Double = 72.0
    @State private var slopeRating: Int = 113
    let onSave: (TeeColor) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Tee Name") {
                    TextField("e.g. Championship/Blue", text: $name)
                }
                Section("Ratings") {
                    HStack {
                        Text("Course Rating")
                        Spacer()
                        TextField("72.0", value: $courseRating,
                                  format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Slope Rating")
                        Spacer()
                        TextField("113", value: $slopeRating, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("Add Tee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(TeeColor(name: name.trimmingCharacters(in: .whitespaces),
                                        courseRating: courseRating,
                                        slopeRating: slopeRating))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
