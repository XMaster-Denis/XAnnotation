//
//  ProjectViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 25.09.24.
//

import SwiftUI
import Combine

class ProjectDataViewModel: ObservableObject {
    @Published var projectSettings: ProjectSettings?
    @Published var foldersInProject: [String] = []
    @Published var selectedFolder: String?
    @Published var allowImageRotation: Bool = false
    @Published var selectedImageURL: URL?
    @Published var projectURL: URL?
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(){
        $allowImageRotation
            .receive(on: DispatchQueue.main) // Required to perform saving only after changing the value
            .sink { _ in
                self.saveProjectSettings()
            }
            .store(in: &cancellables)
    }
    
    func createNewProject() {
        let savePanel = NSSavePanel()
        savePanel.title = "Выберите папку для сохранения проекта"
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "Новый проект"

        if savePanel.runModal() == .OK, let projectFolderURL = savePanel.url {
            self.projectURL = projectFolderURL

            // Создаем структуру папок внутри проекта
            do {
                let imagesFolderURL = projectFolderURL.appendingPathComponent("images")
                let settingsFolderURL = projectFolderURL.appendingPathComponent("settings")

                try FileManager.default.createDirectory(at: imagesFolderURL, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(at: settingsFolderURL, withIntermediateDirectories: true, attributes: nil)

                self.foldersInProject = []

                // Сохраняем настройки проекта (если необходимо)
                saveProjectSettings()

            } catch {
                printLog("Ошибка при создании структуры проекта: \(error.localizedDescription)")
            }
        }
    }
    
    func saveProjectSettings() {
        guard let projectURL = projectURL else { return }
        let settingsURL = projectURL.appendingPathComponent("projectSettings.json")

        let projectSettings = ProjectSettings(
            foldersInProject: foldersInProject,
            selectedFolder: selectedFolder,
            allowImageRotation: allowImageRotation,
            selectedImageURL: selectedImageURL?.lastPathComponent ?? "")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(projectSettings)
            try data.write(to: settingsURL)
        } catch {
            printLog("Ошибка при сохранении настроек проекта: \(error.localizedDescription)")
        }
    }

    func loadProjectSettings() {
        guard let projectURL = projectURL else {
            printLog("Проект не выбран.")
            return
        }
        
        let settingsURL = projectURL.appendingPathComponent("projectSettings.json")

        do {
            let data = try Data(contentsOf: settingsURL)
            let decoder = JSONDecoder()
            let projectSettings = try decoder.decode(ProjectSettings.self, from: data)
            self.foldersInProject = projectSettings.foldersInProject
            self.selectedFolder = projectSettings.selectedFolder
            self.allowImageRotation = projectSettings.allowImageRotation
            
            if let selectedFolder = projectSettings.selectedFolder, let selectedImageURL = projectSettings.selectedImageURL {
                self.selectedImageURL = projectURL
                    .appendingPathComponent("images")
                    .appendingPathComponent(selectedFolder)
                    .appendingPathComponent(selectedImageURL)
            }
            printLog("Проект '" + projectURL.lastPathComponent + "' загружен")
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .typeMismatch(let type, let context):
                printLog("Type Mismatch: \(type), context: \(context)")
            case .valueNotFound(let type, let context):
                printLog("Value not found: \(type), context: \(context)")
            case .keyNotFound(let key, let context):
                printLog("Key '\(key)' not found: \(context.debugDescription)")
            case .dataCorrupted(let context):
                printLog("Data corrupted: \(context.debugDescription)")
            @unknown default:
                printLog("Unknown decoding error: \(decodingError.localizedDescription)")
            }
        } catch {
            printLog("Ошибка при загрузке настроек проекта: \(error.localizedDescription)")
        }
    }
}
