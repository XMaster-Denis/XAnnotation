//
//  ImageThumbnailsViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 25.09.24.
//

import SwiftUI

class ImageThumbnailsViewModel: ObservableObject {
    @Published  var imageURLs: [URL] = []
    @Published  var thumbnailURLs: [URL] = []
    
    
    @Published  var isCreatingThumbnails = false
    @Published  var isLoadingThumbnails = false
    @Published  var creationProgress: Double = 0.0
    @Published  var loadingProgress: Double = 0.0
    var isProjectLaunch: Bool = false
    
    var projectData: ProjectDataViewModel
    init(projectData: ProjectDataViewModel) {
        self.projectData = projectData
    }
    
    func goToNextImage() {
        guard let selectedImageURL = projectData.selectedImageURL else {return}
        if let currentIndex = imageURLs.firstIndex(of: selectedImageURL) {
            let nextIndex = imageURLs.index(after: currentIndex)
            if nextIndex < imageURLs.endIndex {
                projectData.selectedImageURL = imageURLs[nextIndex]
            } else {
                projectData.selectedImageURL = imageURLs.first
            }
        }
    }
    func goToPreviousImage() {
        guard let selectedImageURL = projectData.selectedImageURL else {return}
        if let currentIndex = imageURLs.firstIndex(of: selectedImageURL) {
            let previousIndex = imageURLs.index(before: currentIndex)
            if previousIndex > imageURLs.startIndex {
                projectData.selectedImageURL = imageURLs[previousIndex]
            } else {
                projectData.selectedImageURL = imageURLs.last
            }
        }
    }
    
    func addImageFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select a folder with images to add to the project"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let sourceFolderURL = openPanel.url, let projectURL = projectData.projectURL {
            do {
                let folderName = sourceFolderURL.lastPathComponent
                let destinationFolderURL = projectURL.appendingPathComponent("images").appendingPathComponent(folderName)
                
                try FileManager.default.copyItem(at: sourceFolderURL, to: destinationFolderURL)
                
                // Add a folder to the project folder list
                projectData.foldersInProject.append(folderName)
                projectData.saveProjectSettings()
                
                // Update the image list if this folder is selected
                projectData.selectedFolder = folderName
                loadImages(from: destinationFolderURL)
                
                
            } catch {
                print("Error adding folder with images: \(error.localizedDescription)")
            }
        }
    }
    
    func loadImagesForSelectedFolder(firstLaunch: Bool = false) {
        self.isProjectLaunch = firstLaunch
        guard let projectURL = projectData.projectURL, let selectedFolder = projectData.selectedFolder else {
            print("guard")
            return }
        let folderURL = projectURL.appendingPathComponent("images").appendingPathComponent(selectedFolder)
        loadImages(from: folderURL)
    }
    
    
    
    func loadImages(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let keys: [URLResourceKey] = [.isDirectoryKey]
            
            guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: keys) else { return }
            
            var urls: [URL] = []
            
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(keys))
                    if resourceValues.isDirectory == false, fileURL.isImageFile {
                        urls.append(fileURL)
                    }
                } catch {
                    print("Ошибка при получении свойств файла: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                self.imageURLs = urls
                self.createThumbnails()
            }
        }
    }
    
    func createThumbnails() {
        guard let projectURL = projectData.projectURL, let selectedFolder = projectData.selectedFolder else { return }
        
        isCreatingThumbnails = true
        creationProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnailFolderURL = projectURL.appendingPathComponent("thumbnails").appendingPathComponent(selectedFolder)
            let fileManager = FileManager.default
            
            if !fileManager.fileExists(atPath: thumbnailFolderURL.path) {
                do {
                    try fileManager.createDirectory(at: thumbnailFolderURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Ошибка при создании папки для миниатюр: \(error.localizedDescription)")
                }
            }
            
            let totalImages = self.imageURLs.count
            for (index, imageURL) in self.imageURLs.enumerated() {
                let thumbnailURL = thumbnailFolderURL.appendingPathComponent(imageURL.lastPathComponent)
                
                if !fileManager.fileExists(atPath: thumbnailURL.path) {
                    if let image = NSImage(contentsOf: imageURL) {
                        let thumbnailSize = NSSize(width: 100, height: 100)
                        let thumbnail = image.resizeMaintainingAspectRatio(to: thumbnailSize)
                        thumbnail.savePNG(to: thumbnailURL)
                    }
                }
                
                DispatchQueue.main.async {
                    self.creationProgress = Double(index + 1) / Double(totalImages)
                }
            }
            
            DispatchQueue.main.async {
                self.isCreatingThumbnails = false
                self.loadThumbnails()
            }
        }
    }
    
    func loadThumbnails() {
        guard let projectURL = projectData.projectURL, let selectedFolder = projectData.selectedFolder else { return }
        
        isLoadingThumbnails = true
        loadingProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnailFolderURL = projectURL.appendingPathComponent("thumbnails").appendingPathComponent(selectedFolder)
            let fileManager = FileManager.default
            
            do {
                let thumbnailFiles = try fileManager.contentsOfDirectory(at: thumbnailFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                DispatchQueue.main.async {
                    self.thumbnailURLs = thumbnailFiles
                    self.isLoadingThumbnails = false
                    if !self.isProjectLaunch {self.projectData.selectedImageURL = self.imageURLs.first}
                    self.isProjectLaunch = false
                }
            } catch {
                print("Ошибка при загрузке миниатюр: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingThumbnails = false
                }
            }
        }
    }
    
    
    
    
    
    func getImageURL(forThumbnailURL thumbnailURL: URL) -> URL {
        guard let projectURL = projectData.projectURL, let selectedFolder = projectData.selectedFolder else { return thumbnailURL }
        let imageName = thumbnailURL.lastPathComponent
        let imageURL = projectURL.appendingPathComponent("images").appendingPathComponent(selectedFolder).appendingPathComponent(imageName)
        return imageURL
    }
    
}


