//
//  ContentView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

struct ContentView: View {
    @State private var imageURLs: [URL] = []
    @State private var thumbnailURLs: [URL] = []
    @State private var projectURL: URL?
    @State private var selectedImageURL: URL?
    @State private var isCreatingThumbnails = false
    @State private var isLoadingThumbnails = false
    @State private var creationProgress: Double = 0.0
    @State private var loadingProgress: Double = 0.0
    @State private var annotations: [AnnotationData] = []
    @State private var classList: [ClassData] = []
    @State private var selectedClass: ClassData? = nil
    @State private var foldersInProject: [String] = []
    @State private var selectedFolder: String?
    @State private var showSaveAlert: Bool = false
    @State private var saveAlertMessage: String = ""
    
    var body: some View {
        VStack {
            // Верхние кнопки
            HStack {
                Button("Создать новый проект") {
                    createNewProject()
                }
                .padding()
    
                Button("Открыть проект") {
                    openProject()
                }
                .padding()
    
                if !annotations.isEmpty {
                    Button("Сохранить аннотации") {
                        saveAnnotationsToFile()
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
            if isCreatingThumbnails {
                // Отображение индикатора прогресса при создании миниатюр
                VStack {
                    ProgressView("Создание миниатюр...", value: creationProgress, total: 1.0)
                        .padding()
                    Text("\(Int(creationProgress * 100))% завершено")
                }
            } else if isLoadingThumbnails {
                // Отображение индикатора прогресса при загрузке миниатюр
                VStack {
                    ProgressView("Загрузка миниатюр...", value: loadingProgress, total: 1.0)
                        .padding()
                    Text("\(Int(loadingProgress * 100))% завершено")
                }
            } else if projectURL != nil {
                HStack {
                    // Левая часть: миниатюры изображений
                    Divider()
                    VStack {
                        // Список папок
    
                        ScrollView(.vertical) {
                            VStack(alignment: .leading) {
                                ForEach(foldersInProject, id: \.self) { folderName in
                                    Button(action: {
                                        self.selectedFolder = folderName
                                        loadImagesForSelectedFolder()
                                    }) {
                                        Text(folderName)
                                            .bold()
                                            .cornerRadius(5)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .background(selectedFolder == folderName ? Color.blue.opacity(1) : Color.clear)
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
                                ForEach(thumbnailURLs, id: \.self) { url in
                                    Button(action: {
                                        self.selectedImageURL = getImageURL(forThumbnailURL: url)
                                    }) {
                                        AsyncImageView(url: url, size: CGSize(width: 100, height: 100))
                                            .padding(5)
                                            .border(selectedImageURL == getImageURL(forThumbnailURL: url) ? Color.blue : Color.clear, width: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .frame(minWidth: 100, maxWidth: 150)
    
                    Divider()
    
                    // Центральная часть: аннотирование изображения
                    VStack {
                        if let selectedImageURL = selectedImageURL {
                            AnnotationView(
                                imageURL: selectedImageURL,
                                annotations: $annotations,
                                classList: $classList,
                                selectedClass: $selectedClass,
                                projectURL: $projectURL,
                                saveAnnotations: saveAnnotationsToFile
                            )
                        } else {
                            Text("Выберите изображение для аннотирования")
                                .padding()
                        }
                    }
                    .frame(minWidth: 400, maxWidth: .infinity)
    
                    Divider()
    
                    // Правая часть: список классов (заменяем на ClassListView)
                    ClassListView(
                        classList: $classList,
                        selectedClass: $selectedClass,
                        saveClassListToFile: saveClassListToFile,
                        saveProjectSettings: saveProjectSettings
                    )
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
        guard let projectURL = projectURL else {
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
        let allAnnotatedImages = annotations
        
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
        
        print("Экспорт в CreateML завершён.")
    }
    
    // MARK: - Функции для управления проектом и аннотациями

    func createNewProject() {
        let savePanel = NSSavePanel()
        savePanel.title = "Выберите папку для сохранения проекта"
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "Новый проект"

        if savePanel.runModal() == .OK, let projectFolderURL = savePanel.url {
            self.projectURL = projectFolderURL

            // Создаем структуру папок внутри проекта
            do {
                let imagesFolderURL = projectFolderURL.appendingPathComponent("images")
                let annotationsFolderURL = projectFolderURL.appendingPathComponent("annotations")
                let settingsFolderURL = projectFolderURL.appendingPathComponent("settings")

                try FileManager.default.createDirectory(at: imagesFolderURL, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(at: annotationsFolderURL, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(at: settingsFolderURL, withIntermediateDirectories: true, attributes: nil)

                // Инициализируем пустые данные проекта
                self.imageURLs = []
                self.thumbnailURLs = []
                self.selectedImageURL = nil
                self.classList = []
                self.annotations = []
                self.foldersInProject = []

                // Сохраняем настройки проекта (если необходимо)
                saveProjectSettings()

            } catch {
                print("Ошибка при создании структуры проекта: \(error.localizedDescription)")
            }
        }
    }
    
    
    func openProject() {
        let dialog = NSOpenPanel()
        dialog.title = "Выберите папку проекта"
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.allowsMultipleSelection = false

        if dialog.runModal() == .OK, let projectFolderURL = dialog.url {
            self.projectURL = projectFolderURL

            // Загружаем настройки проекта
            loadProjectSettings()

            // Загружаем список классов и аннотаций
            loadClassListFromFile()
            loadAnnotationsFromFile()

            // Если выбрана папка, загружаем изображения
            if selectedFolder != nil {
                loadImagesForSelectedFolder()
            }
        }
    }



    func addImageFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Выберите папку с изображениями для добавления в проект"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let sourceFolderURL = openPanel.url, let projectURL = self.projectURL {
            do {
                let folderName = sourceFolderURL.lastPathComponent
                let destinationFolderURL = projectURL.appendingPathComponent("images").appendingPathComponent(folderName)

                // Копируем папку с изображениями в проект
                try FileManager.default.copyItem(at: sourceFolderURL, to: destinationFolderURL)

                // Добавляем папку в список папок проекта
                self.foldersInProject.append(folderName)
                saveProjectSettings()

                // Обновляем список изображений, если эта папка выбрана
                if selectedFolder == folderName {
                    loadImages(from: destinationFolderURL)
                }

            } catch {
                print("Ошибка при добавлении папки с изображениями: \(error.localizedDescription)")
            }
        }
    }

    func loadImagesForSelectedFolder() {
        guard let projectURL = projectURL, let selectedFolder = selectedFolder else { return }
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
        guard let projectURL = projectURL, let selectedFolder = selectedFolder else { return }

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
        guard let projectURL = projectURL, let selectedFolder = selectedFolder else { return }

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
                }
            } catch {
                print("Ошибка при загрузке миниатюр: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingThumbnails = false
                }
            }
        }
    }



    func saveAnnotationsToFile() {
        guard let projectURL = projectURL else {
            saveAlertMessage = "Проект не выбран."
            showSaveAlert = true
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
            saveAlertMessage = "Ошибка при сохранении аннотаций: \(error.localizedDescription)"
            showSaveAlert = true
        }
    }

    func loadAnnotationsFromFile() {
        // Загрузка аннотаций из файла
        guard let projectURL = projectURL else { return }

        let annotationsURL = projectURL.appendingPathComponent("annotations.json")

        do {
            let data = try Data(contentsOf: annotationsURL)
            let decoder = JSONDecoder()
            annotations = try decoder.decode([AnnotationData].self, from: data)
        } catch {
            print("Ошибка при загрузке аннотаций: \(error.localizedDescription)")
        }
    }



    func getImageURL(forThumbnailURL thumbnailURL: URL) -> URL {
        guard let projectURL = projectURL, let selectedFolder = selectedFolder else { return thumbnailURL }
        let imageName = thumbnailURL.lastPathComponent
        let imageURL = projectURL.appendingPathComponent("images").appendingPathComponent(selectedFolder).appendingPathComponent(imageName)
        return imageURL
    }

    // Управление классами

    func addClass() {
        // Эта функция теперь управляется в ClassListView.swift
    }

    // Функция для удаления класса
    func deleteClass(at offsets: IndexSet) {
        // Эта функция теперь управляется в ClassListView.swift
    }


    func loadClassListFromFile() {
        do {
            if let projectURL = self.projectURL {
                let classesFileURL = projectURL.appendingPathComponent("classes.json")
                let jsonData = try Data(contentsOf: classesFileURL)
                let decoder = JSONDecoder()
                self.classList = try decoder.decode([ClassData].self, from: jsonData)
                print("Список классов загружен из файла.")
                
                // Устанавливаем выбранный класс, если он не установлен
                if selectedClass == nil, let firstClass = classList.first {
                    selectedClass = firstClass
                }
            }
        } catch {
            print("Ошибка при загрузке списка классов: \(error.localizedDescription)")
        }
    }
    
    // Функция сохранения списка классов в файл
    func saveClassListToFile() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(classList)
            if let projectURL = self.projectURL {
                let classesFileURL = projectURL.appendingPathComponent("classes.json")
                try jsonData.write(to: classesFileURL)
                print("Список классов сохранен по пути: \(classesFileURL.path)")
            }
        } catch {
            print("Ошибка при сохранении списка классов: \(error.localizedDescription)")
        }
    }
    
    func saveProjectSettings() {
        guard let projectURL = projectURL else { return }
        let settingsURL = projectURL.appendingPathComponent("settings").appendingPathComponent("projectSettings.json")

        let projectSettings = ProjectSettings(foldersInProject: foldersInProject, selectedFolder: selectedFolder, classList: classList)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(projectSettings)
            try data.write(to: settingsURL)
        } catch {
            print("Ошибка при сохранении настроек проекта: \(error.localizedDescription)")
        }
    }

    func loadProjectSettings() {
        guard let projectURL = projectURL else {
            print("Проект не выбран.")
            return
        }
        
        let settingsURL = projectURL.appendingPathComponent("settings").appendingPathComponent("projectSettings.json")

        do {
            let data = try Data(contentsOf: settingsURL)
            let decoder = JSONDecoder()
            let projectSettings = try decoder.decode(ProjectSettings.self, from: data)
            self.foldersInProject = projectSettings.foldersInProject
            self.selectedFolder = projectSettings.selectedFolder
            self.classList = projectSettings.classList
            print("Настройки проекта успешно загружены.")
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("Type Mismatch: \(type), context: \(context)")
            case .valueNotFound(let type, let context):
                print("Value not found: \(type), context: \(context)")
            case .keyNotFound(let key, let context):
                print("Key '\(key)' not found: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error: \(decodingError.localizedDescription)")
            }
        } catch {
            print("Ошибка при загрузке настроек проекта: \(error.localizedDescription)")
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
