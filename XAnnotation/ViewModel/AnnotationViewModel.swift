//  AnnotationViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 25.09.24.
//

import Foundation

class AnnotationViewModel: ObservableObject {
    @Published var annotations: [AnnotationData] = []
    var projectData: ProjectDataViewModel = .init()
    
    
    // Function to delete all annotations for the current image
    func deleteAllAnnotationsForCurrentImage() {
        guard let projectURL = projectData.projectURL else {
            printLog("Project not set.")
            return
        }
        
        guard let imageURL = projectData.selectedImageURL else {
            printLog("imageURL not set.")
            return
        }
        
        let absoluteImagePath = imageURL.path
        let projectPath = projectURL.path
        
        guard absoluteImagePath.hasPrefix(projectPath) else {
            printLog("Image is not in the root project folder.")
            return
        }
        
        let relativePath = String(absoluteImagePath.dropFirst(projectPath.count + 1))
        
        // Find the index of `AnnotationData` for the current image
        guard let annotationDataIndex = annotations.firstIndex(where: { $0.imagePath == relativePath }) else {
            printLog("Annotation for the image not found.")
            return
        }
        
        // Find the index of a specific annotation within `AnnotationData`
        for currentImageAnnotation in currentImageAnnotations {
            guard let annotationIndex = annotations[annotationDataIndex].annotations.firstIndex(where: { $0.id == currentImageAnnotation.id }) else {
                printLog("Specific annotation not found.")
                return
            }
            
            // Delete the annotation
            annotations[annotationDataIndex].annotations.remove(at: annotationIndex)
            

        }

        // If there are no more annotations for the image, delete `AnnotationData`
        if annotations[annotationDataIndex].annotations.isEmpty {
            annotations.remove(at: annotationDataIndex)
        }
        
        // Save updated annotations
        saveAnnotationsToFile()
    }
    
    func numberOfAnnotations(for imagePath: URL) -> Int {

        let pathComponents = imagePath.pathComponents
        let fileName = imagePath.lastPathComponent
        let folder = pathComponents.dropLast()
        let lastTwoFolders = folder.suffix(1)
        let resultComponents = lastTwoFolders + [fileName]
        let result = "images/" + resultComponents.joined(separator: "/")

        if let annotationData = annotations.first(where: { $0.imagePath == result }) {
            return annotationData.annotations.count
        } else {
            return 0
        }
    }
    
    func getRelativePath(_ absoluteImagePath: String) -> String? {
        guard let projectURL = projectData.projectURL else {
            return ""
        }
        let projectPath = projectURL.path
        
        guard absoluteImagePath.hasPrefix(projectPath) else {
            printLog("Image is not in the root project folder.")
            return ""
        }
        
        return String(absoluteImagePath.dropFirst(projectPath.count + 1))
    }
    
    
    /// Filters annotations for the current image
    var currentImageAnnotations: [Annotation] {
        // Get the relative path to the image
        
        guard let imageURL = projectData.selectedImageURL else {
            printLog("imageURL not set.")
            return []
        }
        
        let absoluteImagePath = imageURL.path

        let relativePath =  getRelativePath(absoluteImagePath)
        // Find annotations for the current image
        if let annotationData = annotations.first(where: { $0.imagePath == relativePath }) {
            return annotationData.annotations
        }
        
        // If there are no annotations, return an empty array
        return []
    }
    
    /// Adds a new annotation
    func addAnnotation(imageScale: CGFloat, imageSize: CGSize, currentRect: CGRect, selectedClass: ClassData ) {

        print(currentRect)
        // Y coordinate inversion removed as coordinate system matches
        let normalizedX = currentRect.origin.x * imageScale
        let normalizedY = currentRect.origin.y * imageScale
        let normalizedWidth = currentRect.size.width * imageScale
        let normalizedHeight = currentRect.size.height * imageScale

        // Check and adjust coordinates to keep them within the image bounds
        let clampedX = max(0, normalizedX)
        let clampedY = max(0, normalizedY)
        let clampedWidth = min(normalizedWidth, Double(imageSize.width) * Double(imageScale) - clampedX)
        let clampedHeight = min(normalizedHeight, Double(imageSize.height) * Double(imageScale) - clampedY)


        let newAnnotation = Annotation(
            label: selectedClass.name,
            coordinates: Coordinates(
                x: Double(clampedX),
                y: Double(clampedY),
                width: Double(clampedWidth),
                height: Double(clampedHeight)
            )
        )
        
        guard let projectURL = projectData.projectURL else {
            printLog("Project not set.")
            return
        }
        
        guard let imageURL = projectData.selectedImageURL else {
            printLog("imageURL not set.")
            return
        }
        // Assumes imageURL is the URL of the image being annotated
        let absoluteImagePath = imageURL.path
        let projectPath = projectURL.path
        
        // Check if the image is within the project root folder
        guard absoluteImagePath.hasPrefix(projectPath) else {
            printLog("Image is not in the root project folder.")
            return
        }
        
        // Get the relative path
        let relativePath = String(absoluteImagePath.dropFirst(projectPath.count + 1)) // +1 to remove "/"
        printLog("relativePath \(relativePath)")
        // Find an existing entry for the image and add the annotation
        if let index = annotations.firstIndex(where: { $0.imagePath == relativePath }) {
            printLog("annotations.first \(annotations.first!.imagePath)")
            annotations[index].annotations.append(newAnnotation)
        } else {
            // If the entry doesn't exist, add a new one with a unique UUID
            let annotationData = AnnotationData(
                imagePath: relativePath,
                annotations: [newAnnotation]
            )
            annotations.append(annotationData)
        }
        
        // Save annotations
        saveAnnotationsToFile()
    }
    
    func updateAnnotations(from oldClassName: String, to newClassName: String) {
        for i in 0..<annotations.count {
            for j in 0..<annotations[i].annotations.count {
                if annotations[i].annotations[j].label == oldClassName {
                    annotations[i].annotations[j].label = newClassName
                }
            }
        }
        // Save updated annotations
        saveAnnotationsToFile()
        // Update user interface if needed
    }
    
    /// Resizes an annotation
    func resizeAnnotation(annotation: Annotation, handle: ResizableHandle.HandlePosition, newPosition: CGPoint, imageScale: CGFloat, imageSize: CGSize) {
        guard let projectURL = projectData.projectURL else {
            printLog("Project not set.")
            return
        }
        
        guard let imageURL = projectData.selectedImageURL else {
            printLog("imageURL not set.")
            return
        }
        
        let absoluteImagePath = imageURL.path
        let projectPath = projectURL.path
        
        guard absoluteImagePath.hasPrefix(projectPath) else {
            printLog("Image is not in the root project folder.")
            return
        }
        
        let relativePath = String(absoluteImagePath.dropFirst(projectPath.count + 1))
        
        guard let index = annotations.firstIndex(where: { $0.imagePath == relativePath }) else {
            printLog("Annotation not found.")
            return
        }
        
        guard let annotationIndex = annotations[index].annotations.firstIndex(where: { $0.id == annotation.id }) else {
            printLog("Specific annotation not found.")
            return
        }
        
        var updatedAnnotation = annotations[index].annotations[annotationIndex]
        
        // Convert newPosition back to image coordinates
        let imageX = newPosition.x * Double(imageScale)
        let imageY = newPosition.y * Double(imageScale)
        
        switch handle {
        case .topLeft:
            let newX = min(imageX, updatedAnnotation.coordinates.x + updatedAnnotation.coordinates.width - 10)
            let newY = min(imageY, updatedAnnotation.coordinates.y + updatedAnnotation.coordinates.height - 10)
            let newWidth = updatedAnnotation.coordinates.width + (updatedAnnotation.coordinates.x - newX)
            let newHeight = updatedAnnotation.coordinates.height + (updatedAnnotation.coordinates.y - newY)
            updatedAnnotation.coordinates.x = newX
            updatedAnnotation.coordinates.y = newY
            updatedAnnotation.coordinates.width = newWidth
            updatedAnnotation.coordinates.height = newHeight
        case .topRight:
            let newY = min(imageY, updatedAnnotation.coordinates.y + updatedAnnotation.coordinates.height - 10)
            let newWidth = max(10, imageX - updatedAnnotation.coordinates.x)
            let newHeight = updatedAnnotation.coordinates.height + (updatedAnnotation.coordinates.y - newY)
            updatedAnnotation.coordinates.y = newY
            updatedAnnotation.coordinates.width = newWidth
            updatedAnnotation.coordinates.height = newHeight
        case .bottomLeft:
            let newX = min(imageX, updatedAnnotation.coordinates.x + updatedAnnotation.coordinates.width - 10)
            let newWidth = updatedAnnotation.coordinates.width + (updatedAnnotation.coordinates.x - newX)
            let newHeight = max(10, imageY - updatedAnnotation.coordinates.y)
            updatedAnnotation.coordinates.x = newX
            updatedAnnotation.coordinates.width = newWidth
            updatedAnnotation.coordinates.height = newHeight
        case .bottomRight:
            let newWidth = max(10, imageX - updatedAnnotation.coordinates.x)
            let newHeight = max(10, imageY - updatedAnnotation.coordinates.y)
            updatedAnnotation.coordinates.width = newWidth
            updatedAnnotation.coordinates.height = newHeight
        }
        
        // Limit annotation to image bounds
        updatedAnnotation.coordinates.x = max(0, updatedAnnotation.coordinates.x)
        updatedAnnotation.coordinates.y = max(0, updatedAnnotation.coordinates.y)
        updatedAnnotation.coordinates.width = min(updatedAnnotation.coordinates.width, Double(imageSize.width) * Double(imageScale) - updatedAnnotation.coordinates.x)
        updatedAnnotation.coordinates.height = min(updatedAnnotation.coordinates.height, Double(imageSize.height) * Double(imageScale) - updatedAnnotation.coordinates.y)
        
        // Update annotation
        annotations[index].annotations[annotationIndex] = updatedAnnotation
    }
    
    
    
    func saveAnnotationsToFile() {
        guard let projectURL = projectData.projectURL else {
            printLog("Project not selected.")
            return
        }

        let annotationsURL = projectURL.appendingPathComponent("annotations.json")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(annotations)
            try data.write(to: annotationsURL)
        } catch {
            printLog("Error saving annotations: \(error.localizedDescription)")
        }
    }

    func loadAnnotationsFromFile() {
        // Load annotations from file
        guard let projectURL = projectData.projectURL else { return }

        let annotationsURL = projectURL.appendingPathComponent("annotations.json")

        do {
            let data = try Data(contentsOf: annotationsURL)
            let decoder = JSONDecoder()
            annotations = try decoder.decode([AnnotationData].self, from: data)
        } catch {
            printLog("Error loading annotations: \(error.localizedDescription)")
        }
    }
    
    func deleteAnnotation(annotation: Annotation) {
        guard let projectURL = projectData.projectURL else {
            printLog("Project not set.")
            return
        }
        
        guard let imageURL = projectData.selectedImageURL else {
            printLog("imageURL not set.")
            return
        }
        
        let absoluteImagePath = imageURL.path
        let projectPath = projectURL.path
        
        guard absoluteImagePath.hasPrefix(projectPath) else {
            printLog("Image is not in the root project folder.")
            return
        }
        
        let relativePath = String(absoluteImagePath.dropFirst(projectPath.count + 1))
        
        // Find the index of `AnnotationData` for the current image
        guard let annotationDataIndex = annotations.firstIndex(where: { $0.imagePath == relativePath }) else {
            printLog("Annotation for the image not found.")
            return
        }
        
        // Find the index of a specific annotation within `AnnotationData`
        guard let annotationIndex = annotations[annotationDataIndex].annotations.firstIndex(where: { $0.id == annotation.id }) else {
            printLog("Specific annotation not found.")
            return
        }
        
        // Delete the annotation
        annotations[annotationDataIndex].annotations.remove(at: annotationIndex)
        
        // If there are no more annotations for the image, delete `AnnotationData`
        if annotations[annotationDataIndex].annotations.isEmpty {
            annotations.remove(at: annotationDataIndex)
        }
        
        // Save updated annotations
        saveAnnotationsToFile()
    }
    
    func updateAnnotationClass(annotation: Annotation, newClassName: String) {
        guard let projectURL = projectData.projectURL else {
            printLog("Project not set.")
            return
        }
        
        guard let imageURL = projectData.selectedImageURL else {
            printLog("imageURL not set.")
            return
        }
        
        let absoluteImagePath = imageURL.path
        let projectPath = projectURL.path
        
        guard absoluteImagePath.hasPrefix(projectPath) else {
            printLog("Image is not in the root project folder.")
            return
        }
        
        let relativePath = String(absoluteImagePath.dropFirst(projectPath.count + 1))
        
        // Find the index of `AnnotationData` for the current image
        guard let annotationDataIndex = annotations.firstIndex(where: { $0.imagePath == relativePath }) else {
            printLog("Annotation for the image not found.")
            return
        }
        
        // Find the index of a specific annotation within `AnnotationData`
        guard let annotationIndex = annotations[annotationDataIndex].annotations.firstIndex(where: { $0.id == annotation.id }) else {
            printLog("Specific annotation not found.")
            return
        }
        
        // Update the annotation class
        annotations[annotationDataIndex].annotations[annotationIndex].label = newClassName
        
        // Save updated annotations
        saveAnnotationsToFile()
    }
}
