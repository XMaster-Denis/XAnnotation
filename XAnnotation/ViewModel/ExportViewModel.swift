//
//  ExportViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 08.10.24.
//
import SwiftUI

class ExportViewModel: ObservableObject {
    
    var projectData: ProjectDataViewModel = .init()
    var annotationsData: AnnotationViewModel = .init()
    
    @Published var isExporting = false
    @Published var trainExportProgress: Double = 0.0
    @Published var testExportProgress: Double = 0.0
    @Published var validExportProgress: Double = 0.0
    
    func startExport() {
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            self.exportToCreateML()
        }
    }
    
    func exportToCreateML() {
        guard let projectURL = projectData.projectURL else {
            printLog("Project not selected.")
            return
        }
        
        let fileManager = FileManager.default
        
        // Определяем путь к папке Training data
        let trainingDataURL = projectURL.appendingPathComponent("Training data")
        
        // Если папка Training data существует, очищаем её
        if fileManager.fileExists(atPath: trainingDataURL.path) {
            do {
                let contents = try fileManager.contentsOfDirectory(at: trainingDataURL, includingPropertiesForKeys: nil, options: [])
                for file in contents {
                    try fileManager.removeItem(at: file)
                }
                printLog("The 'Training data' folder has been cleared.")
            } catch {
                printLog("Error clearing 'Training data' folder: \(error.localizedDescription)")
                return
            }
        } else {
            // If the folder does not exist, create it
            do {
                try fileManager.createDirectory(at: trainingDataURL, withIntermediateDirectories: true, attributes: nil)
                printLog("The 'Training data' folder has been created.")
            } catch {
                printLog("Error creating folder 'Training data':\(error.localizedDescription)")
                return
            }
        }
        
        // Create the train, test and valid folders inside Training data
        let trainURL = trainingDataURL.appendingPathComponent("train")
        let testURL = trainingDataURL.appendingPathComponent("test")
        let validURL = trainingDataURL.appendingPathComponent("valid")
        
        do {
            try fileManager.createDirectory(at: trainURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: testURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: validURL, withIntermediateDirectories: true, attributes: nil)
            printLog("The 'train', 'test' and 'valid' folders have been created.")
        } catch {
            printLog("Error creating folders 'train', 'test' and 'valid': \(error.localizedDescription)")
            return
        }
        
        // Собираем все аннотированные изображения из всех папок проекта
        let allAnnotatedImages = annotationsData.annotations
        
        let totalImages = allAnnotatedImages.count
        guard totalImages > 0 else {
            printLog("There are no annotated images to export.")
            return
        }
        
        // Перемешиваем массив для случайного распределения
        let shuffledImages = allAnnotatedImages.shuffled()
        
        // Вычисляем количество изображений для каждой папки
        var trainCount = Int(Double(totalImages) * 0.8)
        var testCount = Int(Double(totalImages) * 0.1)
        var validCount = Int(Double(totalImages) * 0.1)
        
        // Корректировка, чтобы общее количество соответствовало
        let remainder = totalImages - (trainCount + testCount + validCount)
        if remainder > 0 {
            trainCount += remainder
        }
        
        // Гарантируем, что в каждой папке будет хотя бы по одному изображению
        if trainCount == 0 && totalImages >= 1 {
            trainCount = 1
        }
        if testCount == 0 && totalImages >= 2 {
            testCount = 1
        }
        if validCount == 0 && totalImages >= 3 {
            validCount = 1
        }
        
        // Разделяем изображения по папкам

        let trainImages = Array(shuffledImages.prefix(trainCount))
        let testImages = Array(shuffledImages.dropFirst(trainCount).prefix(testCount))
        let validImages = Array(shuffledImages.dropFirst(trainCount + testCount).prefix(validCount))
        
        let group = DispatchGroup()
        

        
        // Обрабатываем каждую из папок train, test, valid
        group.enter()
        processImages(trainImages, to: trainURL, folderType: .train) {
            group.leave()
        }
        
        group.enter()
        processImages(testImages, to: testURL, folderType: .test) {
            group.leave()
        }
        
        group.enter()
        processImages(validImages, to: validURL, folderType: .valid) {
            group.leave()
        }
        
        // Ждем завершения всех операций
        group.notify(queue: .main) {
            // Открываем папку 'Training data' в Finder на главном потоке
            self.isExporting = false
            NSWorkspace.shared.open(trainingDataURL)
            printLog("Export to CreateML complete.")
        }
    }
    
    
    
    func processImages(_ images: [AnnotationData], to folderURL: URL, folderType: ExportFolderType, completion: @escaping () -> Void) {
        //  let fileManager = FileManager.default
        var jsonAnnotations: [CreateMLAnnotation] = []
        let allowRotation = projectData.allowImageRotation
        let rotations = allowRotation ? [0, 90, 180, 270] : [0]
        let projectURL = projectData.projectURL!
        
        let processingQueue = OperationQueue()
        processingQueue.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
        
        let annotationsLock = NSLock()
        
        let operations = images.flatMap { annotationData in
            rotations.map { rotationAngle in
                BlockOperation {
                    // Генерируем уникальный идентификатор для каждого изображения
                    let uuid = UUID().uuidString
                    let originalImagePath = annotationData.imagePath
                    let originalExtension = (originalImagePath as NSString).pathExtension
                    let newImageName = "\(uuid).\(originalExtension)"
                    
                    // Определяем пути исходного и целевого изображений
                    let sourceImageURL = projectURL.appendingPathComponent(originalImagePath)
                    let destinationImageURL = folderURL.appendingPathComponent(newImageName)
                    
                    // Загружаем исходное изображение
                    guard let image = NSImage(contentsOf: sourceImageURL) else {
                        printLog("Failed to load image \(originalImagePath)")
                        return
                    }
                    
                    // Поворачиваем изображение, если требуется
                    
                    
                    
                    
                    guard let rotatedImage = self.rotateImage(image: image, byDegrees: CGFloat(rotationAngle)) else {
                        printLog("Failed to rotate image \(originalImagePath)")
                        return
                    }
                    
                    // Сохраняем повернутое изображение
                    do {
                        if let tiffData = rotatedImage.tiffRepresentation,
                           let bitmap = NSBitmapImageRep(data: tiffData),
                           let data = bitmap.representation(using: .jpeg, properties: [:]) {
                            try data.write(to: destinationImageURL)
                            // printLog("Изображение \(originalImagePath) повернуто на \(rotationAngle)° и сохранено как \(newImageName)")
                        } else {
                            printLog("Error saving image \(newImageName)")
                            return
                        }
                    } catch {
                        printLog("Error saving image \(newImageName): \(error.localizedDescription)")
                        return
                    }
                    
                    // Получаем размеры изображения в пикселях
                    guard let cgImage = rotatedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                        return
                    }
                    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                    
                    
                    let transformedAnnotations = self.transformAnnotations(annotationData.annotations, rotationAngle: rotationAngle, originalImageSize: imageSize)
                    //   printLog(transformedAnnotations)
                    // Формируем аннотации для CreateML
                    var regions: [CreateMLRegion] = []
                    for annotation in transformedAnnotations {
                        let centerX = annotation.coordinates.x + (annotation.coordinates.width / 2.0)
                        let centerY = annotation.coordinates.y + (annotation.coordinates.height / 2.0)
                        
                        // Создаём структуру аннотации
                        let region = CreateMLRegion(
                            label: annotation.label,
                            coordinates: CreateMLCoordinates(
                                x: centerX.rounded(),
                                y: centerY.rounded(),
                                width: annotation.coordinates.width.rounded(),
                                height: annotation.coordinates.height.rounded()
                            )
                        )
                        regions.append(region)
                    }
                    
                    // Создаём структуру для JSON
                    let createMLAnnotation = CreateMLAnnotation(
                        image: newImageName,
                        annotations: regions
                    )
                    
                    // Защищаем доступ к общему ресурсу с помощью NSLock
                    annotationsLock.lock()
                    jsonAnnotations.append(createMLAnnotation)
                    annotationsLock.unlock()
                }
            }
        }
        
        // Добавляем блок для отслеживания прогресса
        let totalOperations = operations.count
        var completedOperations = 0
        
        for operation in operations {
            operation.completionBlock = {
                annotationsLock.lock()
                completedOperations += 1
                let progress = Double(completedOperations) / Double(totalOperations)
                DispatchQueue.main.async {
                    switch folderType {
                    case .train:
                        self.trainExportProgress = progress
                        
                    case .test:
                        self.testExportProgress = progress
                        
                    case .valid:
                        self.validExportProgress = progress
                        
                    }
                }
                annotationsLock.unlock()
            }
        }
        
        // Когда все операции завершены, записываем JSON
        processingQueue.addOperations(operations, waitUntilFinished: false)
        processingQueue.addBarrierBlock {
            // Создаём createml.json для текущей папки
            let jsonURL = folderURL.appendingPathComponent("createml.json")
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(jsonAnnotations)
                try data.write(to: jsonURL)
                printLog("File createml.json created in folder \(folderURL.lastPathComponent).")
            } catch {
                printLog("Error creating createml.json in folder \(folderURL.lastPathComponent): \(error.localizedDescription)")
            }
            // Вызываем completion на главном потоке
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func rotateImage(image: NSImage, byDegrees degrees: CGFloat) -> NSImage? {
        // Получаем CGImage из NSImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        // Вычисляем угол в радианах
        let radians = degrees * .pi / 180
        
        // Определяем исходные размеры изображения в пикселях
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let originalSize = CGSize(width: width, height: height)
        
        // Создаем контекст для рендеринга
        var rotatedSize = originalSize
        
        // При повороте на 90 или 270 градусов размеры меняются местами
        if degrees.truncatingRemainder(dividingBy: 180) != 0 {
            rotatedSize = CGSize(width: height, height: width)
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        
        // Устанавливаем `bytesPerRow` для 4 байтов на пиксель (RGBA)
         let bytesPerPixel = 4
         let bytesPerRow = Int(rotatedSize.width) * bytesPerPixel
         
         // Создаем контекст
         guard let context = CGContext(
             data: nil,
             width: Int(rotatedSize.width),
             height: Int(rotatedSize.height),
             bitsPerComponent: 8,
             bytesPerRow: bytesPerRow,
             space: colorSpace,
             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
         ) else {
             return nil
         }
        
        // Перемещаем начало координат в центр изображения
        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        // Поворачиваем контекст
        context.rotate(by: radians)
        // Рисуем изображение в контексте, смещаясь на -width/2 и -height/2
        context.draw(cgImage, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        
        // Получаем новое изображение из контекста
        guard let rotatedCGImage = context.makeImage() else {
            return nil
        }
        
        // Создаем NSImage из CGImage
        let rotatedNSImage = NSImage(cgImage: rotatedCGImage, size: rotatedSize)
        return rotatedNSImage
    }
    
    func transformAnnotations(_ annotations: [Annotation], rotationAngle: Int, originalImageSize: NSSize) -> [Annotation] {
        var transformedAnnotations: [Annotation] = []
        
        // Определяем новый размер изображения после поворота
        let angle = rotationAngle % 360
        
        
        for annotation in annotations {
            var newCoordinates = annotation.coordinates
            
            switch angle {
            case 90, -270:
                newCoordinates = Coordinates(
                    x: annotation.coordinates.y,
                    y: originalImageSize.height - annotation.coordinates.x - annotation.coordinates.width,
                    width: annotation.coordinates.height,
                    height: annotation.coordinates.width
                )
            case 180, -180:
                newCoordinates = Coordinates(
                    x: originalImageSize.width - (annotation.coordinates.x + annotation.coordinates.width),
                    y: originalImageSize.height - (annotation.coordinates.y + annotation.coordinates.height),
                    width: annotation.coordinates.width,
                    height: annotation.coordinates.height
                )
            case 270, -90:
                newCoordinates = Coordinates(
                    x: originalImageSize.width - annotation.coordinates.y - annotation.coordinates.height,
                    y: annotation.coordinates.x,
                    width: annotation.coordinates.height,
                    height: annotation.coordinates.width
                )
            default:
                // Без поворота; координаты остаются прежними
                break
            }
            
            let transformedAnnotation = Annotation(
                id: annotation.id,
                label: annotation.label,
                coordinates: newCoordinates
            )
            transformedAnnotations.append(transformedAnnotation)
        }
        
        return transformedAnnotations
    }
}
