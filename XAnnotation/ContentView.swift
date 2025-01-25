//
//  ContentView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var settings: Settings = Settings.shared
    
    @EnvironmentObject var annotationsData: AnnotationViewModel
    @EnvironmentObject var projectData: ProjectDataViewModel
    @EnvironmentObject var classData: ClassDataViewModel
    @EnvironmentObject var imageThumbnailsData: ImageThumbnailsViewModel
    @EnvironmentObject var exportViewModel: ExportViewModel
    
    var buttonView: some View {
        HStack (spacing : 0) {
            Button("Create a new project") {
                projectData.createNewProject()
            }
            .padding()
            
            Button("Open project") {
                let dialog = NSOpenPanel()
                dialog.title = "Select the project folder"
                dialog.canChooseDirectories = true
                dialog.canChooseFiles = false
                dialog.allowsMultipleSelection = false
                if dialog.runModal() == .OK, let projectFolderURL = dialog.url {
                    projectData.projectURL = projectFolderURL
                    projectData.loadProjectSettings()
                    classData.loadClassListFromFile()
                    annotationsData.loadAnnotationsFromFile()
                    if projectData.selectedFolder != nil {
                        imageThumbnailsData.loadImagesForSelectedFolder(firstLaunch: true)
                    }
                }
            }
            .padding()
  
            
            if !annotationsData.annotations.isEmpty {
                Button("Remove annotations from image") {
                    annotationsData.deleteAllAnnotationsForCurrentImage()
                }
                .padding()
            }
            
            Button("Export for CreateML") {
                exportViewModel.startExport()
            }
            .padding()
            Toggle("Rotate output images", isOn: $projectData.allowImageRotation)
        }
    }
    
    var body: some View {
        
        VStack {
            // Top buttons
            buttonView
            
            // Main content
            if imageThumbnailsData.isCreatingThumbnails {
                // Display a progress indicator while creating thumbnails
                VStack {
                    ProgressView("Creating thumbnails...", value: imageThumbnailsData.creationProgress, total: 1.0)
                        .padding()
                    Text("\(Int(imageThumbnailsData.creationProgress * 100))% completed")
                }
            } else if imageThumbnailsData.isLoadingThumbnails {
                // Show progress indicator while loading thumbnails
                VStack {
                    ProgressView("Loading thumbnails...", value: imageThumbnailsData.loadingProgress, total: 1.0)
                        .padding()
                    Text("\(Int(imageThumbnailsData.loadingProgress * 100))% completed")
                }
            } else if projectData.projectURL != nil {
                HStack {
                    Divider()
                    ImageThumbnailsView()
                    Divider()
                    VStack {
                        if projectData.selectedImageURL != nil {
                            ZStack {
                                StaticImageView()
                                AnnotationView(
                                    updateCrossData: { СrossViewModel.shared.updateCrossData($0) },
                                    updateCrossStatus: { СrossViewModel.shared.updateCrossStatus($0) }
                                )
                            }
                        } else {
                            Text("Select an image to annotate")
                                .padding()
                        }
                    }
                    .frame(minWidth: 400, maxWidth: .infinity)
                    
                    Divider()
                    VStack(alignment: .leading) {
                        ClassListView()
                        Divider()
                        LogView()
                    }
                    .padding(0)
                    .frame(width: 250)
                }
            } else {
                Spacer()
                Text("Project not selected")
                    .padding()
                Spacer()
            }
        }
        .sheet(isPresented: $settings.showExportSettingsView) {
            ExportSettingsView()
        }
        .sheet(isPresented: $exportViewModel.isExporting) {
            ExportModalView()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
