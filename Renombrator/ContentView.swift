import SwiftUI

struct FileRenamerApp: App {
    var body: some Scene {
        WindowGroup {
            WizardView()
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
    }
}

// MARK: - Wizard principal
struct WizardView: View {
    @State private var step = 0
    @State private var selectedURLs: [URL] = []
    
    // Configuración de renombrado
    @State private var capitalizeFirstLetter = false
    @State private var addNumbering = false
    @State private var prefixText = ""
    @State private var suffixText = ""
    
    // Barra de progreso
    @State private var progress: Double = 0
    @State private var isRenaming = false
    @State private var showCompletionMessage = false
    
    var body: some View {
        VStack(spacing: 20) {
            switch step {
            case 0:
                // ✨ Paso 1: Selección de archivos
                VStack(spacing: 12) {
                    Text("Paso 1: Selecciona tus archivos o carpeta")
                        .font(.headline)
                    HStack {
                        Button("Seleccionar archivos") { selectFiles() }
                        Button("Seleccionar carpeta") { selectFolder() }
                        Spacer()
                    }
                    if !selectedURLs.isEmpty {
                        Text("\(selectedURLs.count) archivos seleccionados")
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Button("Siguiente") {
                        if !selectedURLs.isEmpty { step += 1 }
                    }
                    .disabled(selectedURLs.isEmpty)
                }
                .padding()
                
            case 1:
                // ✨ Paso 2: Vista previa de archivos
                VStack(spacing: 12) {
                    Text("Paso 2: Archivos seleccionados")
                        .font(.headline)
                    if selectedURLs.isEmpty {
                        Text("No hay archivos seleccionados")
                            .foregroundColor(.secondary)
                    } else {
                        List(selectedURLs, id: \.self) { url in
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                        }
                        .frame(minHeight: 200)
                    }
                    HStack {
                        Button("Anterior") { step -= 1 }
                        Spacer()
                        Button("Siguiente") { step += 1 }
                    }
                }
                .padding()
                
            case 2:
                // ✨ Paso 3: Configuración de renombrado
                VStack(alignment: .leading, spacing: 12) {
                    Text("Paso 3: Configura el renombrado")
                        .font(.headline)
                    
                    Toggle("Primera letra mayúscula", isOn: $capitalizeFirstLetter)
                    Toggle("Numerar archivos", isOn: $addNumbering)
                    
                    HStack {
                        Text("Prefijo:")
                        TextField("Ej: X_", text: $prefixText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Sufijo:")
                        TextField("Ej: _Final", text: $suffixText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Button("Anterior") { step -= 1 }
                        Spacer()
                        Button("Renombrar") { startRenaming() }
                            .disabled(isRenaming)
                    }
                }
                .padding()
                
            case 3:
                // ✨ Paso 4: Barra de progreso
                VStack(spacing: 12) {
                    Text("Renombrando archivos...")
                        .font(.headline)
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 300)
                    
                    if showCompletionMessage {
                        Text("✅ Archivos renombrados correctamente")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                
            default:
                EmptyView()
            }
        }
        .frame(width: 500, height: 400)
    }
    
    // MARK: - Funciones de selección de archivos
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
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let folder = panel.url {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                selectedURLs = files.filter { $0.isFileURL }
            } catch {
                print("Error leyendo carpeta:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Renombrado
    func startRenaming() {
        isRenaming = true
        progress = 0
        showCompletionMessage = false
        step = 3
        
        DispatchQueue.global(qos: .userInitiated).async {
            let total = selectedURLs.count
            for (index, url) in selectedURLs.enumerated() {
                var newName = url.deletingPathExtension().lastPathComponent
                
                // Aplicar capitalización
                if capitalizeFirstLetter {
                    newName = newName.prefix(1).uppercased() + newName.dropFirst()
                }
                
                // Aplicar numeración
                if addNumbering {
                    newName = "\(index + 1)_\(newName)"
                }
                
                // Prefijo y sufijo
                newName = "\(prefixText)\(newName)\(suffixText)"
                
                // Extensión original
                newName += "." + url.pathExtension
                
                let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
                
                do {
                    try FileManager.default.moveItem(at: url, to: newURL)
                } catch {
                    print("Error renombrando \(url.lastPathComponent): \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    progress = Double(index + 1) / Double(total)
                }
                
                Thread.sleep(forTimeInterval: 0.1) // Solo para que se vea la barra
            }
            
            DispatchQueue.main.async {
                showCompletionMessage = true
                isRenaming = false
            }
        }
    }
}

