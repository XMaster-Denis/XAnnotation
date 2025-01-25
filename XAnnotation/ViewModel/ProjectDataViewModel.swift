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
        savePanel.title = "Select a folder to save the project"
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "New Project"

        if savePanel.runModal() == .OK, let projectFolderURL = savePanel.url {
            self.projectURL = projectFolderURL

            // Create a folder structure inside the project
            do {
                let imagesFolderURL = projectFolderURL.appendingPathComponent("images")
                let settingsFolderURL = projectFolderURL.appendingPathComponent("settings")

                try FileManager.default.createDirectory(at: imagesFolderURL, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(at: settingsFolderURL, withIntermediateDirectories: true, attributes: nil)

                self.foldersInProject = []

                // Save project settings (if necessary)
                saveProjectSettings()

            } catch {
                printLog("Error creating project structure: \(error.localizedDescription)")
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
            printLog("Error saving project settings: \(error.localizedDescription)")
        }
    }

    func loadProjectSettings() {
        guard let projectURL = projectURL else {
            printLog("Project not selected")
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
            printLog("Project ‘%@‘ loaded", data: projectURL.lastPathComponent)
//            printLog("Project '\(projectURL.lastPathComponent)' loaded")
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
            printLog("Error loading project settings: \(error.localizedDescription)")
        }
    }
}
