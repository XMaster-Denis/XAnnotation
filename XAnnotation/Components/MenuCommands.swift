//
//  MenuCommands.swift
//  XAnnotation
//
//  Created by XMaster on 24.10.24.
//

import SwiftUI

struct MenuCommands: Commands {
    @ObservedObject var settings: Settings = Settings.shared
    @ObservedObject var imageThumbnailsData: ImageThumbnailsViewModel
    @ObservedObject var projectData: ProjectDataViewModel
    

    
    var body: some Commands {

        CommandMenu("Settings".localized) {
            Menu("Export settings".localized){ // "Export settings"
                Toggle("Rotate output images".localized, isOn: $projectData.allowImageRotation)
                Divider()
                Button("Export proportions".localized) {
                    settings.showExportSettingsView = true
                }
            }
            
            Picker(selection: $settings.language, label: Text("Language".localized)) {
                ForEach(Settings.Language.allCases) {language in
                    Text(language.rawValue).tag(language)
                }
            }
        }
        
        CommandMenu("Navigation".localized) {
            Button("Previous image".localized) {
                imageThumbnailsData.goToPreviousImage()
            }
            .disabled(projectData.selectedImageURL == nil)
            .keyboardShortcut("q", modifiers: .option)
            Button("Next Image".localized) {
                imageThumbnailsData.goToNextImage()
                
            }
            .keyboardShortcut("w", modifiers: .option)
            .disabled(projectData.selectedImageURL == nil)
        }
    }
}

