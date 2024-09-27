//
//  ProjectViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 25.09.24.
//

import SwiftUI

class ProjectDataViewModel: ObservableObject {
    @Published var projectSettings: ProjectSettings = .init()
    @Published var foldersInProject: [String] = []
    @Published var selectedFolder: String?

    @Published var selectedImageURL: URL?
    @Published var projectURL: URL?


    
   // func openProject() -> Bool {

   // }
    
    
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
                let annotationsFolderURL = projectFolderURL.appendingPathComponent("annotations")
                let settingsFolderURL = projectFolderURL.appendingPathComponent("settings")

                try FileManager.default.createDirectory(at: imagesFolderURL, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(at: annotationsFolderURL, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(at: settingsFolderURL, withIntermediateDirectories: true, attributes: nil)

               // Инициализируем пустые данные проекта
               // self.imageURLs = []
               // self.thumbnailURLs = []
               // self.selectedImageURL = nil
                //classList = []
                //self.annotations = []
                self.foldersInProject = []

                // Сохраняем настройки проекта (если необходимо)
                saveProjectSettings()

            } catch {
                print("Ошибка при создании структуры проекта: \(error.localizedDescription)")
            }
        }
    }
    
    func saveProjectSettings() {
        guard let projectURL = projectURL else { return }
        let settingsURL = projectURL.appendingPathComponent("settings").appendingPathComponent("projectSettings.json")

        let projectSettings = ProjectSettings(foldersInProject: foldersInProject, selectedFolder: selectedFolder)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(projectSettings)
            try data.write(to: settingsURL)
        } catch {
            print("Ошибка при сохранении настроек проекта: \(error.localizedDescription)")
        }
    }

    func loadProjectSettings() {
        guard let projectURL = projectURL else {
            print("Проект не выбран.")
            return
        }
        
        let settingsURL = projectURL.appendingPathComponent("settings").appendingPathComponent("projectSettings.json")

        do {
            let data = try Data(contentsOf: settingsURL)
            let decoder = JSONDecoder()
            let projectSettings = try decoder.decode(ProjectSettings.self, from: data)
            self.foldersInProject = projectSettings.foldersInProject
            self.selectedFolder = projectSettings.selectedFolder
            print("Настройки проекта успешно загружены.")
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("Type Mismatch: \(type), context: \(context)")
            case .valueNotFound(let type, let context):
                print("Value not found: \(type), context: \(context)")
            case .keyNotFound(let key, let context):
                print("Key '\(key)' not found: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error: \(decodingError.localizedDescription)")
            }
        } catch {
            print("Ошибка при загрузке настроек проекта: \(error.localizedDescription)")
        }
    }
}
