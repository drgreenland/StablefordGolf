import SwiftUI

struct TeeDistanceMatrixView: View {
    @Binding var tees: [TeeColor]
    @Binding var holes: [Hole]

    var body: some View {
        Form {
            Section("Tee Ratings") {
                ForEach(tees.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tees[i].name).font(.headline)
                        HStack {
                            Text("Course Rating")
                            Spacer()
                            TextField("72.0", value: $tees[i].courseRating,
                                      format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        HStack {
                            Text("Slope Rating")
                            Spacer()
                            TextField("113", value: $tees[i].slopeRating, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Distances (m)") {
                ForEach(holes.indices, id: \.self) { hi in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hole \(holes[hi].number)  ·  Par \(holes[hi].par)  ·  SI \(holes[hi].strokeIndex)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(tees.indices, id: \.self) { ti in
                            HStack {
                                Text(tees[ti].name)
                                Spacer()
                                TextField("0", value: distanceBinding(holeIndex: hi, teeId: tees[ti].id),
                                          format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 70)
                                Text("m").foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background { AppColors.grassGradient.ignoresSafeArea() }
        .navigationTitle("Tee Distances")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func distanceBinding(holeIndex: Int, teeId: UUID) -> Binding<Int> {
        Binding(
            get: {
                holes[holeIndex].teeDistances.first(where: { $0.teeId == teeId })?.distance ?? 0
            },
            set: { newValue in
                if let idx = holes[holeIndex].teeDistances.firstIndex(where: { $0.teeId == teeId }) {
                    holes[holeIndex].teeDistances[idx].distance = newValue
                } else {
                    holes[holeIndex].teeDistances.append(TeeDistance(teeId: teeId, distance: newValue))
                }
            }
        )
    }
}
