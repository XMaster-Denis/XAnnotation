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
    
    
    //var projectSettings = projectData.shared
    @EnvironmentObject var annotationsData: AnnotationViewModel
    @EnvironmentObject var projectData: ProjectDataViewModel
    @EnvironmentObject var classData: ClassDataViewModel
    @EnvironmentObject var imageThumbnailsData: ImageThumbnailsViewModel
        // @EnvironmentObject var krestData: СrossViewModel

    
    var body: some View {
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
                            imageThumbnailsData.loadImagesForSelectedFolder()
                        }
                    }
                }
                .onAppear {
                    let projectPath = "/Users/xmaster/Pictures/Новый проект/"
                    let projectURL = URL(fileURLWithPath: projectPath)
                    print("Programmatic URL absoluteString: \(projectURL.absoluteString)")
                    print("Programmatic URL path: \(projectURL.path)")
                    projectData.projectURL = projectURL
                    projectData.loadProjectSettings()
                    classData.loadClassListFromFile()
                    annotationsData.loadAnnotationsFromFile()
                    if projectData.selectedFolder != nil {
                        imageThumbnailsData.loadImagesForSelectedFolder()
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
                    exportToCreateML()
                }
                .padding()
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
                                            //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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
        
        do {
            try fileManager.createDirectory(at: trainURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: testURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: validURL, withIntermediateDirectories: true, attributes: nil)
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
        var trainCount = Int(Double(totalImages) * 0.7)
        var testCount = Int(Double(totalImages) * 0.15)
        var validCount = Int(Double(totalImages) * 0.15)
        
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
        let trainImages = shuffledImages.prefix(trainCount)
        let testImages = shuffledImages.dropFirst(trainCount).prefix(testCount)
        let validImages = shuffledImages.dropFirst(trainCount + testCount).prefix(validCount)
        
        // Функция для копирования и переименования изображений, а также формирования аннотаций
        func processImages(_ images: ArraySlice<AnnotationData>, to folderURL: URL) {
            var jsonAnnotations: [CreateMLAnnotation] = []
            
            for annotationData in images {
                // Получаем UUID и исходное расширение файла
                let uuid = annotationData.id.uuidString
                let originalImagePath = annotationData.imagePath
                let originalExtension = (originalImagePath as NSString).pathExtension
                let newImageName = "\(uuid).\(originalExtension)"
                
                // Определяем пути исходного и целевого изображений
                let sourceImageURL = projectURL.appendingPathComponent(originalImagePath)
                let destinationImageURL = folderURL.appendingPathComponent(newImageName)
                
                // Копируем изображение
                do {
                    try fileManager.copyItem(at: sourceImageURL, to: destinationImageURL)
                  //  print("Изображение \(originalImagePath) скопировано как \(newImageName) в папку \(folderURL.lastPathComponent).")
                } catch {
                    print("Ошибка при копировании изображения \(originalImagePath): \(error.localizedDescription)")
                    continue
                }
                
                // Формируем аннотации для CreateML
                var regions: [CreateMLRegion] = []
                for annotation in annotationData.annotations {
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
                jsonAnnotations.append(createMLAnnotation)
            }
            
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
        }
        
        // Обрабатываем каждую из папок train, test, valid
        processImages(trainImages, to: trainURL)
        processImages(testImages, to: testURL)
        processImages(validImages, to: validURL)
        
        // Открываем папку 'Training data' в Finder
        NSWorkspace.shared.open(trainingDataURL)
        print("Экспорт в CreateML завершён.")
    }
    
    // MARK: - Функции для управления проектом и аннотациями

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
