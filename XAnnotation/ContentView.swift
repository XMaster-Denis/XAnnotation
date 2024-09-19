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
    
    func generateCreateMLJSON() -> [CreateMLAnnotation] {
        // Группируем аннотации по имени изображения
        let groupedAnnotations = Dictionary(grouping: annotations) { $0.image }
        
        var createMLAnnotations: [CreateMLAnnotation] = []
        
        for (imageName, imageAnnotations) in groupedAnnotations {
            // Получаем путь к изображению
            guard let projectURL = self.projectURL,
                  let selectedFolder = self.selectedFolder else {
                print("Проект или выбранная папка не установлены.")
                continue
            }
            
            let imagePath = projectURL
                .appendingPathComponent("images")
                .appendingPathComponent(selectedFolder)
                .appendingPathComponent(imageName)
            
            guard let nsImage = NSImage(contentsOf: imagePath) else {
                print("Не удалось загрузить изображение по пути: \(imagePath.path)")
                continue
            }
            
            let imageWidth = nsImage.size.width
            let imageHeight = nsImage.size.height
            
            print("Processing image: \(imageName) with size: \(imageWidth)x\(imageHeight)")
            
            var regions: [CreateMLRegion] = []
            
            for annotationData in imageAnnotations {
                for annotation in annotationData.annotations {
                    // Вычисляем центр прямоугольника
                    let centerX = annotation.coordinates.x + (annotation.coordinates.width / 2.0)
                    let centerY = annotation.coordinates.y + (annotation.coordinates.height / 2.0)
                    
                    // Проверяем, что координаты не выходят за пределы изображения
                    let clampedX = max(0, min(centerX, imageWidth))
                    let clampedY = max(0, min(centerY, imageHeight))
                    let clampedWidth = max(0, min(annotation.coordinates.width, imageWidth))
                    let clampedHeight = max(0, min(annotation.coordinates.height, imageHeight))
                    
                    // Логирование координат для отладки
                    print("Original Coordinates for annotation '\(annotation.label)': x=\(annotation.coordinates.x), y=\(annotation.coordinates.y), width=\(annotation.coordinates.width), height=\(annotation.coordinates.height)")
                    print("Calculated Center Coordinates: x=\(centerX), y=\(centerY)")
                    print("Clamped Center Coordinates: x=\(clampedX), y=\(clampedY), width=\(clampedWidth), height=\(clampedHeight)")
                    
                    // Создаём регион для CreateML
                    let region = CreateMLRegion(
                        label: annotation.label,
                        coordinates: CreateMLCoordinates(
                            x: clampedX,
                            y: clampedY,
                            width: clampedWidth,
                            height: clampedHeight
                        )
                    )
                    regions.append(region)
                }
            }
            
            // Создаём аннотацию для изображения
            let createMLAnnotation = CreateMLAnnotation(image: imageName, annotations: regions)
            createMLAnnotations.append(createMLAnnotation)
        }
        
        return createMLAnnotations
    }
    
 
    func exportToCreateML() {
        guard let projectURL = projectURL else {
            print("Проект не выбран.")
            return
        }
        
        // Открываем диалоговое окно для выбора папки экспорта
        let openPanel = NSOpenPanel()
        openPanel.title = "Выберите папку для экспорта CreateML"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true

        openPanel.begin { response in
            if response == .OK, let exportFolderURL = openPanel.url {
                // Создаём папку для изображений в папке экспорта
                let exportImagesURL = exportFolderURL.appendingPathComponent("images")
                do {
                    try FileManager.default.createDirectory(at: exportImagesURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Ошибка при создании папки для экспорта: \(error.localizedDescription)")
                    return
                }
                
                // Копируем все изображения из проекта в папку экспорта
                for folder in foldersInProject {
                    let sourceFolderURL = projectURL.appendingPathComponent("images").appendingPathComponent(folder)
                    let destinationFolderURL = exportImagesURL.appendingPathComponent(folder)
                    do {
                        try FileManager.default.copyItem(at: sourceFolderURL, to: destinationFolderURL)
                    } catch {
                        print("Ошибка при копировании папки \(folder): \(error.localizedDescription)")
                    }
                }
                
                // Генерируем JSON-файл в формате CreateML
                let createMLJSON = generateCreateMLJSON()
                let jsonURL = exportFolderURL.appendingPathComponent("createml.json")
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(createMLJSON)
                    try data.write(to: jsonURL)
                    print("CreateML JSON успешно сохранён по адресу: \(jsonURL.path)")
                } catch {
                    print("Ошибка при сохранении CreateML JSON: \(error.localizedDescription)")
                }
            } else {
                print("Экспорт отменён пользователем.")
            }
        }
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

extension NSImage {
    func resizeMaintainingAspectRatio(to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    func savePNG(to url: URL) {
        guard let tiffData = self.tiffRepresentation else { return }
        guard let bitmap = NSBitmapImageRep(data: tiffData) else { return }
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return }

        do {
            try data.write(to: url)
        } catch {
            print("Ошибка при сохранении изображения: \(error.localizedDescription)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
