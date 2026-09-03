import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var exportFile: ExportFile? = nil
    @State private var showingImporter = false
    @State private var importMode: ImportMode = .data
    @State private var showingClearConfirm = false
    @State private var alertMessage: String? = nil

    var body: some View {
        Form {
            Section("Data") {
                Button {
                    exportAllData()
                } label: {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }

                Button {
                    importMode = .data
                    showingImporter = true
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }

                Button {
                    importMode = .course
                    showingImporter = true
                } label: {
                    Label("Import Course (course-mapper)", systemImage: "map")
                }
            }

            Section("Danger Zone") {
                Button(role: .destructive) {
                    showingClearConfirm = true
                } label: {
                    Label("Clear All Data", systemImage: "trash")
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Bundle ID", value: "com.davidgreenland.StablefordGolf")
            }
        }
        .scrollContentBackground(.hidden)
        .background { AppColors.grassGradient.ignoresSafeArea() }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $exportFile) { file in
            ShareSheet(activityItems: [file.url])
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .confirmationDialog("Clear All Data?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
            Button("Clear All Data", role: .destructive) { dataManager.clearAllData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all players, courses and rounds.")
        }
        .alert("Import Result", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK") { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func exportAllData() {
        guard let data = try? dataManager.exportData() else { return }
        let fileName = "StablefordGolf-backup-\(Date().formatted(.iso8601)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        guard (try? data.write(to: url)) != nil else { return }
        exportFile = ExportFile(url: url)
    }

    private func handleImport(result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            alertMessage = "Could not read file."
            return
        }

        do {
            if importMode == .course {
                try dataManager.importCourse(from: data)
                alertMessage = "Course imported successfully."
            } else {
                try dataManager.importData(data)
                alertMessage = "Data imported successfully."
            }
        } catch {
            alertMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Import mode
enum ImportMode { case data, course }

// MARK: - Export file wrapper (avoids SwiftUI sheet timing race)
struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
