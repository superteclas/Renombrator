import SwiftUI

struct WizardView: View {
    @State private var step = -1 // Nuevo: empezamos en -1 para la pantalla inicial
    @State private var selectedURLs: [URL] = []
    
    // Carpeta de destino
    @State private var destinationFolder: URL? = nil
    
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
        ZStack {
            // Fondo general
            LinearGradient(gradient: Gradient(colors: [.gray.opacity(0.1), .blue.opacity(0.15)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                switch step {
                    
                // MARK: - Pantalla inicial
                case -1:
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.gearshape")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                            .shadow(radius: 5)
                        
                        Text("Renombrator")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Versión 1.0")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text("Renombra tus archivos en un solo clic y sin usar el terminal.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        Button("Comenzar") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                step = 0
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .multilineTextAlignment(.center)
                    
                // MARK: - Paso 1: Selección de archivos
                case 0:
                    VStack(spacing: 20) {
                        Text("Paso 1: Selecciona tus archivos o carpeta")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            Button("Seleccionar archivos") { selectFiles() }
                            Button("Seleccionar carpeta") { selectFolder() }
                        }
                        
                        if !selectedURLs.isEmpty {
                            Text("\(selectedURLs.count) archivos seleccionados")
                                .foregroundColor(.green)
                        } else {
                            Text("Ningún archivo seleccionado")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Siguiente") {
                            if !selectedURLs.isEmpty { step += 1 }
                        }
                        .disabled(selectedURLs.isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: 500, maxHeight: 400)
                    .multilineTextAlignment(.center)
                    
                // MARK: - Paso 2: Vista previa
                case 1:
                    VStack(spacing: 20) {
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
                    .frame(maxWidth: 500, maxHeight: 400)
                    .multilineTextAlignment(.center)
                    
                // MARK: - Paso 3: Configuración
                case 2:
                    VStack(alignment: .leading, spacing: 15) {
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
                            Text("Carpeta destino:")
                            Text(destinationFolder?.path ?? "Usando carpeta original")
                                .lineLimit(1)
                            Spacer()
                            Button("Seleccionar...") { selectDestinationFolder() }
                        }
                        
                        Spacer()
                        
                        HStack {
                            Button("Anterior") { step -= 1 }
                            Spacer()
                            Button("Renombrar") { startRenaming() }
                                .disabled(isRenaming)
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .frame(maxWidth: 500, maxHeight: 400)
                    
                // MARK: - Paso 4: Progreso
                case 3:
                    VStack(spacing: 20) {
                        if showCompletionMessage {
                            // Nueva pantalla final
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.green)
                                .shadow(radius: 5)
                            
                            Text("✅ Archivos renombrados correctamente")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            Button("Reiniciar") {
                                resetWizard()
                            }
                            .buttonStyle(.borderedProminent)
                            
                        } else {
                            Text("Renombrando archivos...")
                                .font(.headline)
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 300)
                        }
                    }
                    .padding()
                    .frame(maxWidth: 500, maxHeight: 400)
                    .multilineTextAlignment(.center)
                    
                default:
                    EmptyView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }
}

// MARK: - Funciones
extension WizardView {
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
    
    func selectDestinationFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Seleccionar"
        if panel.runModal() == .OK, let folder = panel.url {
            destinationFolder = folder
        }
    }
    
    func startRenaming() {
        isRenaming = true
        progress = 0
        showCompletionMessage = false
        step = 3
        
        let destination = destinationFolder ?? selectedURLs.first?.deletingLastPathComponent()
        
        guard let destinationFolder = destination else {
            print("No hay carpeta de destino válida")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let total = selectedURLs.count
            for (index, url) in selectedURLs.enumerated() {
                var newName = url.deletingPathExtension().lastPathComponent
                
                if capitalizeFirstLetter {
                    newName = newName.prefix(1).uppercased() + newName.dropFirst()
                }
                if addNumbering {
                    newName = "\(index + 1)_\(newName)"
                }
                
                newName = "\(prefixText)\(newName)\(suffixText).\(url.pathExtension)"
                let newURL = destinationFolder.appendingPathComponent(newName)
                
                do {
                    try FileManager.default.copyItem(at: url, to: newURL)
                } catch {
                    print("Error renombrando \(url.lastPathComponent): \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    progress = Double(index + 1) / Double(total)
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            DispatchQueue.main.async {
                showCompletionMessage = true
                isRenaming = false
            }
        }
    }
    
    func resetWizard() {
        step = -1
        selectedURLs = []
        destinationFolder = nil
        prefixText = ""
        suffixText = ""
        addNumbering = false
        capitalizeFirstLetter = false
        progress = 0
        showCompletionMessage = false
    }
}

