import SwiftUI
import AppKit

// MARK: - ViewModel
class WizardViewModel: ObservableObject {
    @Published var step: Int = -1
    @Published var selectedURLs: [URL] = []
    @Published var destinationFolder: URL? = nil
    @Published var addNumbering: Bool = false
    @Published var prefixText: String = ""
    @Published var suffixText: String = ""
    @Published var progress: Double = 0
    @Published var isRenaming: Bool = false
    @Published var showCompletionMessage: Bool = false
    @Published var capitalizationOption: WizardView.CapitalizationOption = .none
    @Published var clearNames: Bool = false // ✅ Borra nombres originales
    @Published var customBaseName: String = "" // ✅ Nuevo nombre base personalizado

    func startRenaming(completion: @escaping () -> Void) {
        isRenaming = true
        progress = 0
        showCompletionMessage = false
        step = 3

        guard let destinationFolder = destinationFolder ?? selectedURLs.first?.deletingLastPathComponent() else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let total = self.selectedURLs.count

            for (index, url) in self.selectedURLs.enumerated() {
                var baseName = url.deletingPathExtension().lastPathComponent

                // ✅ Si el usuario borra los nombres originales
                if self.clearNames {
                    if !self.customBaseName.isEmpty {
                        baseName = self.customBaseName
                    } else {
                        baseName = String(format: "%03d", index + 1)
                    }
                }

                var newName = "\(self.prefixText)\(baseName)\(self.suffixText)"

                // ✅ Capitalización
                switch self.capitalizationOption {
                case .firstLetter:
                    newName = newName.prefix(1).uppercased() + newName.dropFirst()
                case .uppercase:
                    newName = newName.uppercased()
                case .lowercase:
                    newName = newName.lowercased()
                case .none:
                    break
                }

                // ✅ Numeración automática si está activada o si se usa nombre personalizado
                if self.addNumbering || self.clearNames {
                    newName = String(format: "%@_%03d", newName, index + 1)
                }

                var newURL = destinationFolder.appendingPathComponent("\(newName).\(url.pathExtension)")
                var counter = 1

                // Evitar sobrescritura
                while FileManager.default.fileExists(atPath: newURL.path) {
                    newURL = destinationFolder.appendingPathComponent("\(newName)_\(counter).\(url.pathExtension)")
                    counter += 1
                }

                // Copiar archivo
                do {
                    try FileManager.default.copyItem(at: url, to: newURL)
                } catch {
                    print("Error renombrando \(url.lastPathComponent): \(error.localizedDescription)")
                }

                DispatchQueue.main.async {
                    self.progress = Double(index + 1) / Double(total)
                }

                Thread.sleep(forTimeInterval: 0.05)
            }

            DispatchQueue.main.async {
                self.showCompletionMessage = true
                self.isRenaming = false
                NSSound(named: NSSound.Name("Glass"))?.play()
                completion()
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
        clearNames = false
        customBaseName = ""
        capitalizationOption = .none
        progress = 0
        showCompletionMessage = false
    }
}

// MARK: - Main View
struct WizardView: View {
    @StateObject private var viewModel = WizardViewModel()

    enum CapitalizationOption: String, CaseIterable, Identifiable {
        case none = "Normal"
        case firstLetter = "Primera letra mayúscula"
        case uppercase = "Todo mayúsculas"
        case lowercase = "Todo minúsculas"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.gray.opacity(0.1), .blue.opacity(0.15)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo
                Image("Image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .shadow(radius: 5)
                    .padding(.top, 70)

                Spacer()

                // Pasos del asistente
                Group {
                    switch viewModel.step {
                    case -1: StepIntro(viewModel: viewModel)
                    case 0: StepSelectFiles(viewModel: viewModel)
                    case 1: StepPreview(viewModel: viewModel)
                    case 2: StepConfigure(viewModel: viewModel)
                    case 3: StepProgress(viewModel: viewModel) {
                        showCompletionAlert()
                    }
                    default: EmptyView()
                    }
                }

                Spacer()
            }
        }
    }

    private func showCompletionAlert() {
        let alert = NSAlert()
        alert.messageText = "Renombrado completado ✅"
        alert.informativeText = "Todos los archivos se han renombrado correctamente."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        if let logoImage = NSImage(named: "Image") {
            alert.icon = logoImage
        }
        alert.runModal()
    }
}

// MARK: - Pantalla 1: Introducción
struct StepIntro: View {
    @ObservedObject var viewModel: WizardViewModel
    var body: some View {
        VStack(spacing: 20) {
            Text("Renombrator").font(.largeTitle).bold()
            Text("Versión 1.2").font(.footnote).foregroundColor(.secondary)
            Text("Renombra, limpia o crea nuevos nombres personalizados para tus archivos de forma rápida.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Button("Comenzar") {
                withAnimation(.easeInOut(duration: 0.5)) { viewModel.step = 0 }
            }
            .buttonStyle(.borderedProminent)
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Pantalla 2: Selección de archivos
struct StepSelectFiles: View {
    @ObservedObject var viewModel: WizardViewModel
    var body: some View {
        VStack(spacing: 20) {
            Text("Paso 1: Selecciona tus archivos o carpeta").font(.headline)
            HStack(spacing: 20) {
                Button("Seleccionar archivos") { selectFiles() }
                Button("Seleccionar carpeta") { selectFolder() }
            }
            Text(viewModel.selectedURLs.isEmpty ? "Ningún archivo seleccionado" : "\(viewModel.selectedURLs.count) archivos seleccionados")
                .foregroundColor(viewModel.selectedURLs.isEmpty ? .secondary : .green)
            Button("Siguiente") { viewModel.step += 1 }
                .disabled(viewModel.selectedURLs.isEmpty)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: 500)
    }

    func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.item]
        if panel.runModal() == .OK {
            viewModel.selectedURLs = panel.urls
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
                viewModel.selectedURLs = files.filter { $0.isFileURL }
            } catch {
                print("Error leyendo carpeta:", error.localizedDescription)
            }
        }
    }
}

// MARK: - Pantalla 3: Vista previa
struct StepPreview: View {
    @ObservedObject var viewModel: WizardViewModel
    var body: some View {
        VStack(spacing: 20) {
            Text("Paso 2: Archivos seleccionados").font(.headline)
            if viewModel.selectedURLs.isEmpty {
                Text("No hay archivos seleccionados").foregroundColor(.secondary)
            } else {
                List(viewModel.selectedURLs, id: \.self) { url in
                    Text(url.lastPathComponent).lineLimit(1)
                }
                .frame(minHeight: 200)
            }
            HStack {
                Button("Anterior") { viewModel.step -= 1 }
                Spacer()
                Button("Siguiente") { viewModel.step += 1 }
            }
        }
        .padding()
        .frame(maxWidth: 500)
    }
}

// MARK: - Pantalla 4: Configuración
struct StepConfigure: View {
    @ObservedObject var viewModel: WizardViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Paso 3: Configura el renombrado").font(.headline)

            Picker("Capitalización:", selection: $viewModel.capitalizationOption) {
                ForEach(WizardView.CapitalizationOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Toggle("Borrar nombres originales", isOn: $viewModel.clearNames)

            if viewModel.clearNames {
                HStack {
                    Text("Nuevo nombre base:")
                    TextField("Ej: Foto", text: $viewModel.customBaseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }

            Toggle("Numerar archivos", isOn: $viewModel.addNumbering)
                .disabled(viewModel.clearNames)

            HStack {
                Text("Prefijo:")
                TextField("Ej: X_", text: $viewModel.prefixText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.clearNames)
            }

            HStack {
                Text("Sufijo:")
                TextField("Ej: _Final", text: $viewModel.suffixText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.clearNames)
            }

            HStack {
                Text("Carpeta destino:")
                Text(viewModel.destinationFolder?.path ?? "Usando carpeta original")
                    .lineLimit(1)
                Spacer()
                Button("Seleccionar...") { selectDestinationFolder() }
            }

            HStack {
                Button("Anterior") { viewModel.step -= 1 }
                Spacer()
                Button("Renombrar") {
                    viewModel.startRenaming() {}
                }
                .disabled(viewModel.isRenaming)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: 500)
    }

    func selectDestinationFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Seleccionar"
        if panel.runModal() == .OK, let folder = panel.url {
            viewModel.destinationFolder = folder
        }
    }
}

// MARK: - Pantalla 5: Progreso
struct StepProgress: View {
    @ObservedObject var viewModel: WizardViewModel
    var completion: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.showCompletionMessage {
                Text("✅ Archivos renombrados correctamente").font(.title2).foregroundColor(.green)
                HStack(spacing: 20) {
                    if let destination = viewModel.destinationFolder ?? viewModel.selectedURLs.first?.deletingLastPathComponent() {
                        Button("Abrir carpeta") { NSWorkspace.shared.open(destination) }
                            .buttonStyle(.borderedProminent)
                    }
                    Button("Reiniciar") { viewModel.resetWizard() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Renombrando archivos...").font(.headline)
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 300)
            }
        }
        .padding()
        .frame(maxWidth: 500)
        .onChange(of: viewModel.showCompletionMessage) { _ in
            if viewModel.showCompletionMessage {
                completion()
            }
        }
    }
}

