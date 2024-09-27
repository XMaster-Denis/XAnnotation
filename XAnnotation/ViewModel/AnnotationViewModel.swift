//
//  AnnotationViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 25.09.24.
//

import Foundation

class AnnotationViewModel: ObservableObject {
    @Published var annotations: [AnnotationData] = []
    var projectData: ProjectDataViewModel
    
    init(projectData: ProjectDataViewModel) {
        self.projectData = projectData
    }
    
    /// Фильтрует аннотации для текущего изображения
    var currentImageAnnotations: [Annotation] {
        // Получаем относительный путь к изображению
        guard let projectURL = projectData.projectURL else {
            print("Проект не установлен.")
            return []
        }
        
        guard let imageURL = projectData.selectedImageURL else {
            print("imageURL не установлен.")
            return []
        }
        
        let absoluteImagePath = imageURL.path
        let projectPath = projectURL.path
        
        // Проверяем, что изображение находится внутри корневой папки проекта
        guard absoluteImagePath.hasPrefix(projectPath) else {
            print("Изображение не находится в корневой папке проекта.")
            return []
        }
        
        // Вычисляем относительный путь
        let relativePath = String(absoluteImagePath.dropFirst(projectPath.count + 1)) // +1 для удаления "/"
        
        // Ищем аннотации для текущего изображения
        if let annotationData = annotations.first(where: { $0.imagePath == relativePath }) {
            return annotationData.annotations
        }
        
        // Если аннотаций нет, возвращаем пустой массив
        return []
    }
    
    /// Добавляет новую аннотацию
    func addAnnotation(imageScale: CGFloat, imageSize: CGSize, currentRect: CGRect, selectedClass: ClassData ) {
//        guard let selectedClass = projectData.selectedClass else {
//            // Если класс не выбран, не сохраняем аннотацию
//            print("Класс не выбран. Пожалуйста, выберите класс перед аннотированием.")
//            return
//        }

        print(currentRect)
        // Инверсия Y координаты убрана, так как система координат совпадает
        let normalizedX = currentRect.origin.x * imageScale
        let normalizedY = currentRect.origin.y * imageScale
        let normalizedWidth = currentRect.size.width * imageScale
        let normalizedHeight = currentRect.size.height * imageScale

        // Проверка и корректировка координат, чтобы они не выходили за границы изображения
        let clampedX = max(0, normalizedX)
        let clampedY = max(0, normalizedY)
        let clampedWidth = min(normalizedWidth, Double(imageSize.width) * Double(imageScale) - clampedX)
        let clampedHeight = min(normalizedHeight, Double(imageSize.height) * Double(imageScale) - clampedY)

        print("Normalized Coordinates (after clamping):")
        print("X: \(clampedX), Y: \(clampedY), Width: \(clampedWidth), Height: \(clampedHeight)")

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
            print("Проект не установлен.")
            return
        }
        
        guard let imageURL = projectData.selectedImageURL else {
            print("imageURL не установлен.")
            return
        }
        // Предполагается, что imageURL является URL изображения, которое аннотируется
        let absoluteImagePath = imageURL.path
        let projectPath = projectURL.path
        
        // Проверяем, что изображение находится внутри корневой папки проекта
        guard absoluteImagePath.hasPrefix(projectPath) else {
            print("Изображение не находится в корневой папке проекта.")
            return
        }
        
        // Получаем относительный путь
        let relativePath = String(absoluteImagePath.dropFirst(projectPath.count + 1)) // +1 для удаления "/"
        print("relativePath \(relativePath)")
        // Найти существующую запись для изображения и добавить аннотацию
        if let index = annotations.firstIndex(where: { $0.imagePath == relativePath }) {
            print("annotations.first \(annotations.first!.imagePath)")
            annotations[index].annotations.append(newAnnotation)
        } else {
            // Если запись не существует, добавить новую с уникальным UUID
            let annotationData = AnnotationData(
                imagePath: relativePath,
                annotations: [newAnnotation]
            )
            annotations.append(annotationData)
        }
        
        // Сохраняем аннотации
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
        // Сохраняем обновленные аннотации
        saveAnnotationsToFile()
        // Обновляем интерфейс пользователя, если необходимо
    }
    
    /// Ресайзит аннотацию
    func resizeAnnotation(annotation: Annotation, handle: ResizableHandle.HandlePosition, newPosition: CGPoint, imageScale: CGFloat, imageSize: CGSize) {
        guard let projectURL = projectData.projectURL else {
            print("Проект не установлен.")
            return
        }
        
        guard let imageURL = projectData.selectedImageURL else {
            print("imageURL не установлен.")
            return
        }
        
        let absoluteImagePath = imageURL.path
        let projectPath = projectURL.path
        
        guard absoluteImagePath.hasPrefix(projectPath) else {
            print("Изображение не находится в корневой папке проекта.")
            return
        }
        
        let relativePath = String(absoluteImagePath.dropFirst(projectPath.count + 1))
        
        guard let index = annotations.firstIndex(where: { $0.imagePath == relativePath }) else {
            print("Аннотация не найдена.")
            return
        }
        
        guard let annotationIndex = annotations[index].annotations.firstIndex(where: { $0.id == annotation.id }) else {
            print("Конкретная аннотация не найдена.")
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
        
        // Ограничиваем аннотацию границами изображения
        updatedAnnotation.coordinates.x = max(0, updatedAnnotation.coordinates.x)
        updatedAnnotation.coordinates.y = max(0, updatedAnnotation.coordinates.y)
        updatedAnnotation.coordinates.width = min(updatedAnnotation.coordinates.width, Double(imageSize.width) * Double(imageScale) - updatedAnnotation.coordinates.x)
        updatedAnnotation.coordinates.height = min(updatedAnnotation.coordinates.height, Double(imageSize.height) * Double(imageScale) - updatedAnnotation.coordinates.y)
        
        // Обновляем аннотацию
        annotations[index].annotations[annotationIndex] = updatedAnnotation
    }
    
    
    
    func saveAnnotationsToFile() {
        guard let projectURL = projectData.projectURL else {
            print("Проект не выбран.")
            return
        }

        let annotationsURL = projectURL.appendingPathComponent("annotations.json")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(annotations)
            try data.write(to: annotationsURL)
            print("Аннотации успешно сохранены по адресу: \(annotationsURL.path)")
        } catch {
            print("Ошибка при сохранении аннотаций: \(error.localizedDescription)")
        }
    }

    func loadAnnotationsFromFile() {
        // Загрузка аннотаций из файла
        guard let projectURL = projectData.projectURL else { return }

        let annotationsURL = projectURL.appendingPathComponent("annotations.json")

        do {
            let data = try Data(contentsOf: annotationsURL)
            let decoder = JSONDecoder()
            annotations = try decoder.decode([AnnotationData].self, from: data)
        } catch {
            print("Ошибка при загрузке аннотаций: \(error.localizedDescription)")
        }
    }
}
