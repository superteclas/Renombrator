import SwiftUI


struct FileRenamerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
    }
}

struct ContentView: View {
    @State private var selectedURLs: [URL] = []
    @State private var showingFilePicker = false
    @State private var showingFolderPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("Seleccionar archivos") {
                    selectFiles()
                }
                Button("Seleccionar carpeta") {
                    selectFolder()
                }
                Spacer()
            }

            Divider()

            if selectedURLs.isEmpty {
                Text("No hay archivos seleccionados.")
                    .foregroundColor(.secondary)
            } else {
                List(selectedURLs, id: \.self) { url in
                    Text(url.lastPathComponent)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                }
                .frame(minHeight: 200)
            }

            Spacer()
        }
        .padding()
        .frame(width: 500, height: 400)
    }

    // MARK: - Métodos
    func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.item]
        if panel.runModal() == .OK {
            selectedURLs = panel.urls
        }
    }

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let folder = panel.url {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                selectedURLs = files.filter { $0.isFileURL }
            } catch {
                print("Error leyendo carpeta:", error.localizedDescription)
            }
        }
    }
}

