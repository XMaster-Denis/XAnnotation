//
//  ContentView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

struct ContentView: View {


    @State private var showSaveAlert: Bool = false
    @State private var saveAlertMessage: String = ""
    
    
    @EnvironmentObject var annotationsData: AnnotationViewModel
    @EnvironmentObject var projectData: ProjectDataViewModel
    @EnvironmentObject var classData: ClassDataViewModel
    @EnvironmentObject var imageThumbnailsData: ImageThumbnailsViewModel
    @EnvironmentObject var exportViewModel: ExportViewModel


    
    var body: some View {
        ZStack{
            VStack {
                // Верхние кнопки
                HStack (spacing : 0) {
                    Button("Создать новый проект") {
                        projectData.createNewProject()
                    }
                    .padding()
                    
                    Button("Открыть проект") {
                        let dialog = NSOpenPanel()
                        dialog.title = "Выберите папку проекта"
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
                        Button("Удалить все аннотации") {
                            annotationsData.deleteAllAnnotationsForCurrentImage()
                        }
                        .padding()
                    }
                    
                    // Новая кнопка для экспорта
                    Button("Экспортировать в CreateML") {
                        startExport()
                    }
                    .padding()
                    
                    
                    Toggle("Крутить изображения", isOn: $projectData.allowImageRotation)
                }
                
                // Основной контент
                if imageThumbnailsData.isCreatingThumbnails {
                    // Отображение индикатора прогресса при создании миниатюр
                    VStack {
                        ProgressView("Создание миниатюр...", value: imageThumbnailsData.creationProgress, total: 1.0)
                            .padding()
                        Text("\(Int(imageThumbnailsData.creationProgress * 100))% завершено")
                    }
                } else if imageThumbnailsData.isLoadingThumbnails {
                    // Отображение индикатора прогресса при загрузке миниатюр
                    VStack {
                        ProgressView("Загрузка миниатюр...", value: imageThumbnailsData.loadingProgress, total: 1.0)
                            .padding()
                        Text("\(Int(imageThumbnailsData.loadingProgress * 100))% завершено")
                    }
                } else if projectData.projectURL != nil {
                    HStack {
                        // Левая часть: миниатюры изображений
                        Divider()
                        
                        VStack {
                            // Список папок
                            
                            ScrollView(.vertical) {
                                VStack(alignment: .leading) {
                                    ForEach(projectData.foldersInProject, id: \.self) { folderName in
                                        Button(action: {
                                            projectData.selectedFolder = folderName
                                            imageThumbnailsData.loadImagesForSelectedFolder()
                                            
                                        }) {
                                            Text(folderName)
                                                .bold()
                                                .cornerRadius(5)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .background(projectData.selectedFolder == folderName ? Color.blue.opacity(1) : Color.clear)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            
                            // Кнопка для добавления новой папки
                            Button(action: addImageFolder) {
                                Text("Добавить папку с изображениями")
                            }
                            
                            // Отображение миниатюр изображений
                            ScrollView(.vertical) {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                                    ForEach(imageThumbnailsData.thumbnailURLs, id: \.self) { url in
                                        ZStack (alignment: .topTrailing) {
                                            
                                            Button(action: {
                                                projectData.selectedImageURL = imageThumbnailsData.getImageURL(forThumbnailURL: url)

                                                projectData.saveProjectSettings()
                                            }) {
                                                AsyncImageView(url: url, size: CGSize(width: 120, height: 120))
                                                    .padding(2)
                                                    .border(projectData.selectedImageURL == imageThumbnailsData.getImageURL(forThumbnailURL: url) ? Color.blue : Color.clear, width: 2)
                                                
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            let numberOfAnnotations: Int = annotationsData.numberOfAnnotations(for: url)
                                            Text("\(numberOfAnnotations)")
                                                .padding(.horizontal, 3)
                                                .padding(.vertical, 1)
                                            
                                                .background(
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .fill(Color.green)
                                                )
                                                .foregroundColor(.red)
                                                .font(.title)
                                                .offset(x: -5, y: 5)
                                            
                                            
                                        }
                                    }
                                }
                            }
                        }
                        .frame(minWidth: 100, maxWidth: 150)
                        
                        Divider()
                        
                        // Центральная часть: аннотирование изображения
                        VStack {
                            if projectData.selectedImageURL != nil {
                                ZStack {
                                    StaticImageView()
                                    
                                    //                                AnnotationView()
                                    AnnotationView(
                                        //imageGeometry: imageGeometry,
                                        updateCrossData: { СrossViewModel.shared.updateCrossData($0) },
                                        updateCrossStatus: { СrossViewModel.shared.updateCrossStatus($0) }
                                    )
                                }
                            } else {
                                Text("Выберите изображение для аннотирования")
                                    .padding()
                            }
                        }
                        .frame(minWidth: 400, maxWidth: .infinity)
                        
                        Divider()
                        
                        ClassListView()
                    }
                } else {
                    Spacer()
                    Text("Проект не выбран")
                        .padding()
                    Spacer()
                }
            }
            .alert(isPresented: $showSaveAlert) {
                Alert(title: Text("Сохранение аннотаций"), message: Text(saveAlertMessage), dismissButton: .default(Text("OK")))
            }
            .frame(minWidth: 800, minHeight: 600)
        }
        if exportViewModel.isExporting {
            ProgressView(value: exportViewModel.exportProgress)
                .padding()
        }
    }
    
    func startExport() {
        exportViewModel.isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            self.exportToCreateML()
        }
    }
    
    func exportToCreateML() {
        guard let projectURL = projectData.projectURL else {
            print("Проект не выбран.")
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
                print("Папка 'Training data' очищена.")
            } catch {
                print("Ошибка при очистке папки 'Training data': \(error.localizedDescription)")
                return
            }
        } else {
            // Если папки не существует, создаём её
            do {
                try fileManager.createDirectory(at: trainingDataURL, withIntermediateDirectories: true, attributes: nil)
                print("Папка 'Training data' создана.")
            } catch {
                print("Ошибка при создании папки 'Training data': \(error.localizedDescription)")
                return
            }
        }
        
        // Создаём папки train, test и valid внутри Training data
        let trainURL = trainingDataURL.appendingPathComponent("train")
        let testURL = trainingDataURL.appendingPathComponent("test")
        let validURL = trainingDataURL.appendingPathComponent("valid")
        let allURL = trainingDataURL.appendingPathComponent("all")
        
        do {
            try fileManager.createDirectory(at: trainURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: testURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: validURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: allURL, withIntermediateDirectories: true, attributes: nil)
            print("Папки 'train', 'test' и 'valid' созданы.")
        } catch {
            print("Ошибка при создании папок 'train', 'test' и 'valid': \(error.localizedDescription)")
            return
        }
        
        // Собираем все аннотированные изображения из всех папок проекта
        let allAnnotatedImages = annotationsData.annotations
        
        let totalImages = allAnnotatedImages.count
        guard totalImages > 0 else {
            print("Нет аннотированных изображений для экспорта.")
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
        //        let trainImages = shuffledImages.prefix(trainCount)
        //        let testImages = shuffledImages.dropFirst(trainCount).prefix(testCount)
        //        let validImages = shuffledImages.dropFirst(trainCount + testCount).prefix(validCount)
        let trainImages = Array(shuffledImages.prefix(trainCount))
        let testImages = Array(shuffledImages.dropFirst(trainCount).prefix(testCount))
        let validImages = Array(shuffledImages.dropFirst(trainCount + testCount).prefix(validCount))
        
        let group = DispatchGroup()
        
        // Обрабатываем папку 'all' со всеми изображениями
//            group.enter()
//            processImages(allAnnotatedImages, to: allURL) {
//                group.leave()
//            }
            
            // Обрабатываем каждую из папок train, test, valid
            group.enter()
            processImages(trainImages, to: trainURL) {
                group.leave()
            }
            
            group.enter()
            processImages(testImages, to: testURL) {
                group.leave()
            }
            
            group.enter()
            processImages(validImages, to: validURL) {
                group.leave()
            }
            
            // Ждем завершения всех операций
            group.notify(queue: .main) {
                // Открываем папку 'Training data' в Finder на главном потоке
                self.exportViewModel.isExporting = false
                NSWorkspace.shared.open(trainingDataURL)
                print("Экспорт в CreateML завершён.")
            }
            
//            // Обрабатываем папку 'all' со всеми изображениями
//            processImages(allAnnotatedImages, to: allURL)
//            // Обрабатываем каждую из папок train, test, valid
//            processImages(trainImages, to: trainURL)
//            processImages(testImages, to: testURL)
//            processImages(validImages, to: validURL)
            
//            // Открываем папку 'Training data' в Finder
//            NSWorkspace.shared.open(trainingDataURL)
//            print("Экспорт в CreateML завершён.")
        }
    
    // MARK: - Функции для управления проектом и аннотациями

    // Функция для копирования и переименования изображений, а также формирования аннотаций
//    func processImages(_ images: [AnnotationData], to folderURL: URL) {
//        guard let projectURL = projectData.projectURL else {
//            print("Проект не выбран.")
//            return
//        }
//  
//        
//        var jsonAnnotations: [CreateMLAnnotation] = []
//        let allowRotation = projectData.allowImageRotation
//        let rotations = allowRotation ? [0, 90, 180, 270] : [0]
//        
//        for annotationData in images {
//            for rotationAngle in rotations {
//                // Получаем UUID и исходное расширение файла
//                let uuid = annotationData.id.uuidString
//                let originalImagePath = annotationData.imagePath
//                let originalExtension = (originalImagePath as NSString).pathExtension
//                let newImageName = "\(uuid).\(originalExtension)"
//                
//                // Определяем пути исходного и целевого изображений
//                let sourceImageURL = projectURL.appendingPathComponent(originalImagePath)
//                let destinationImageURL = folderURL.appendingPathComponent(newImageName)
//                
//                // Загружаем исходное изображение
//                guard let image = NSImage(contentsOf: sourceImageURL) else {
//                    print("Не удалось загрузить изображение \(originalImagePath)")
//                    continue
//                }
//                
//                // Поворачиваем изображение, если требуется
//                let rotatedImage = rotateImage(image: image, byDegrees: rotationAngle)
//                
//                
//                
//                // Копируем изображение
////                do {
////                    try fileManager.copyItem(at: sourceImageURL, to: destinationImageURL)
////                    //  print("Изображение \(originalImagePath) скопировано как \(newImageName) в папку \(folderURL.lastPathComponent).")
////                } catch {
////                    print("Ошибка при копировании изображения \(originalImagePath): \(error.localizedDescription)")
////                    continue
////                }
//                
//                // Сохраняем повернутое изображение
//                 do {
//                     if let tiffData = rotatedImage.tiffRepresentation,
//                        let bitmap = NSBitmapImageRep(data: tiffData),
//                        let data = bitmap.representation(using: .jpeg, properties: [:]) {
//                         try data.write(to: destinationImageURL)
//                         // print("Изображение \(originalImagePath) повернуто на \(rotationAngle)° и сохранено как \(newImageName)")
//                     } else {
//                         print("Ошибка при сохранении изображения \(newImageName)")
//                         continue
//                     }
//                 } catch {
//                     print("Ошибка при сохранении изображения \(newImageName): \(error.localizedDescription)")
//                     continue
//                 }
//                
//                // Преобразуем аннотации в соответствии с поворотом
//                let transformedAnnotations = transformAnnotations(annotationData.annotations, rotationAngle: rotationAngle, imageSize: image.size)
//                
//                
//                // Формируем аннотации для CreateML
//                var regions: [CreateMLRegion] = []
//                for annotation in transformedAnnotations {
//                    let centerX = annotation.coordinates.x + (annotation.coordinates.width / 2.0)
//                    let centerY = annotation.coordinates.y + (annotation.coordinates.height / 2.0)
//                    
//                    // Создаём структуру аннотации
//                    let region = CreateMLRegion(
//                        label: annotation.label,
//                        coordinates: CreateMLCoordinates(
//                            x: centerX.rounded(),
//                            y: centerY.rounded(),
//                            width: annotation.coordinates.width.rounded(),
//                            height: annotation.coordinates.height.rounded()
//                        )
//                    )
//                    regions.append(region)
//                }
//                
//                // Создаём структуру для JSON
//                let createMLAnnotation = CreateMLAnnotation(
//                    image: newImageName,
//                    annotations: regions
//                )
//                jsonAnnotations.append(createMLAnnotation)
//            }
//            
//            // Создаём createml.json для текущей папки
//            let jsonURL = folderURL.appendingPathComponent("createml.json")
//            do {
//                let encoder = JSONEncoder()
//                encoder.outputFormatting = .prettyPrinted
//                let data = try encoder.encode(jsonAnnotations)
//                try data.write(to: jsonURL)
//                print("Файл createml.json создан в папке \(folderURL.lastPathComponent).")
//            } catch {
//                print("Ошибка при создании createml.json в папке \(folderURL.lastPathComponent): \(error.localizedDescription)")
//            }
//        }
//    }
//    
    
    func processImages(_ images: [AnnotationData], to folderURL: URL, completion: @escaping () -> Void) {
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
//                    let destinationImageURL2 = folderURL.appendingPathComponent("1"+newImageName)
                    
                    // Загружаем исходное изображение
                    guard let image = NSImage(contentsOf: sourceImageURL) else {
                        print("Не удалось загрузить изображение \(originalImagePath)")
                        return
                    }
                    
                    // Поворачиваем изображение, если требуется


                    
           
                    guard let rotatedImage = rotateImage(image: image, byDegrees: CGFloat(rotationAngle)) else {
                        print("Не удалось повернуть изображение \(originalImagePath)")
                        return
                    }

                    // Сохраняем повернутое изображение
                    do {
                        if let tiffData = rotatedImage.tiffRepresentation,
                           let bitmap = NSBitmapImageRep(data: tiffData),
                           let data = bitmap.representation(using: .jpeg, properties: [:]) {
                            try data.write(to: destinationImageURL)
                            // print("Изображение \(originalImagePath) повернуто на \(rotationAngle)° и сохранено как \(newImageName)")
                        } else {
                            print("Ошибка при сохранении изображения \(newImageName)")
                            return
                        }
                    } catch {
                        print("Ошибка при сохранении изображения \(newImageName): \(error.localizedDescription)")
                        return
                    }
                    
//                    do {
//                        if let tiffData = rotatedImage.tiffRepresentation,
//                           let bitmap = NSBitmapImageRep(data: tiffData),
//                           let data = bitmap.representation(using: .jpeg, properties: [:]) {
//                            try data.write(to: destinationImageURL2)
//                            // print("Изображение \(originalImagePath) повернуто на \(rotationAngle)° и сохранено как \(newImageName)")
//                        } else {
//                            print("Ошибка при сохранении изображения \(newImageName)")
//                            return
//                        }
//                    } catch {
//                        print("Ошибка при сохранении изображения \(newImageName): \(error.localizedDescription)")
//                        return
//                    }
                    
                    
                    
                    // Преобразуем аннотации в соответствии с поворотом
                 //   print(annotationData.annotations)
                    // Внутри операции обработки изображения


                    // Получаем размеры изображения в пикселях
                    guard let cgImage = rotatedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                        return
                    }
                    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                    
                    
                    let transformedAnnotations = transformAnnotations(annotationData.annotations, rotationAngle: rotationAngle, originalImageSize: imageSize)
                 //   print(transformedAnnotations)
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
                    self.exportViewModel.exportProgress = progress
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
                print("Файл createml.json создан в папке \(folderURL.lastPathComponent).")
            } catch {
                print("Ошибка при создании createml.json в папке \(folderURL.lastPathComponent): \(error.localizedDescription)")
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

        guard let colorSpace = cgImage.colorSpace else {
            return nil
        }

        guard let context = CGContext(
            data: nil,
            width: Int(rotatedSize.width),
            height: Int(rotatedSize.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
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
    
    func addImageFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Выберите папку с изображениями для добавления в проект"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let sourceFolderURL = openPanel.url, let projectURL = projectData.projectURL {
            do {
                let folderName = sourceFolderURL.lastPathComponent
                let destinationFolderURL = projectURL.appendingPathComponent("images").appendingPathComponent(folderName)

                // Копируем папку с изображениями в проект
                try FileManager.default.copyItem(at: sourceFolderURL, to: destinationFolderURL)

                // Добавляем папку в список папок проекта
                projectData.foldersInProject.append(folderName)
                projectData.saveProjectSettings()

                // Обновляем список изображений, если эта папка выбрана
                projectData.selectedFolder = folderName
                imageThumbnailsData.loadImages(from: destinationFolderURL)
                

            } catch {
                print("Ошибка при добавлении папки с изображениями: \(error.localizedDescription)")
            }
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
