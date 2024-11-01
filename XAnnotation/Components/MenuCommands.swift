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
        CommandMenu("Settings") {
            Menu("Export settings"){
                Toggle("Rotate output images", isOn: $projectData.allowImageRotation)
            }
            
            Picker(selection: $settings.language, label: Text("Language")) {
                ForEach(Settings.Language.allCases) {language in
                    Text(language.rawValue).tag(language)
                }
            }
        }
        
        CommandMenu("Navigation") {
            Button("Previous image") {
                imageThumbnailsData.goToPreviousImage()
            }
            .disabled(projectData.selectedImageURL == nil)
            .keyboardShortcut("q", modifiers: .option)
            Button("Next Image") {
                imageThumbnailsData.goToNextImage()
            }
            .keyboardShortcut("w", modifiers: .option)
            .disabled(projectData.selectedImageURL == nil)
        }
    }
}

