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
    @State private var classList: [String] = []
    @State private var newClassName: String = ""
    @State private var selectedClass: String?

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
            } else if !thumbnailURLs.isEmpty {
                HStack {
                    // Левая часть: миниатюры изображений
                    ScrollView {
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
                    .frame(minWidth: 100, maxWidth: 150)
                    .padding()

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

                    // Правая часть: список классов
                    VStack(alignment: .leading) {
                        Text("Список классов:")
                            .font(.headline)
                        List(selection: $selectedClass) {
                            ForEach(classList, id: \.self) { className in
                                Text(className)
                                    .tag(className)
                            }
                            .onDelete(perform: deleteClass)
                        }
                        VStack {
                            TextField("Добавить класс", text: $newClassName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: addClass) {
                                Text("Добавить")
                            }
                        }
                        .padding()
                        if selectedClass == nil {
                            Text("Пожалуйста, выберите класс для аннотирования.")
                                .foregroundColor(.red)
                        } else {
                            Text("Текущий выбранный класс: \(selectedClass!)")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .frame(maxWidth: 250)
                }
            } else {
                Spacer()
                Text("Проект не выбран")
                    .padding()
                Spacer()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    // Функции для управления проектом и аннотациями

    
    
    func createNewProject() {
         let dialog = NSOpenPanel()
         dialog.title = "Выберите папку с изображениями"
         dialog.canChooseDirectories = true
         dialog.canChooseFiles = false
         dialog.allowsMultipleSelection = false

         if dialog.runModal() == .OK, let imagesFolderURL = dialog.url {
             // Создаем папку проекта
             let savePanel = NSSavePanel()
             savePanel.title = "Сохранить проект как"
             savePanel.canCreateDirectories = true
             savePanel.nameFieldStringValue = "Новый проект"

             if savePanel.runModal() == .OK, let projectFolderURL = savePanel.url {
                 do {
                     try FileManager.default.createDirectory(at: projectFolderURL, withIntermediateDirectories: true, attributes: nil)
                     self.projectURL = projectFolderURL

                     // Копируем изображения в папку проекта
                     let imagesDestinationURL = projectFolderURL.appendingPathComponent("images")
                     try FileManager.default.createDirectory(at: imagesDestinationURL, withIntermediateDirectories: true, attributes: nil)
                     let imageFiles = try FileManager.default.contentsOfDirectory(at: imagesFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                     for imageFile in imageFiles {
                         let destinationURL = imagesDestinationURL.appendingPathComponent(imageFile.lastPathComponent)
                         try FileManager.default.copyItem(at: imageFile, to: destinationURL)
                     }

                     projectURL = projectFolderURL
                     loadImages(from: imagesFolderURL)
                     // Очищаем список классов и аннотаций
                     self.classList = []
                     self.annotations = []

                     // Сохраняем пустые файлы классов и аннотаций
                     saveClassListToFile()
                     saveAnnotationsToFile()
                   

                 } catch {
                     print("Ошибка при создании проекта: \(error.localizedDescription)")
                 }
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

            // Загружаем список классов
            loadClassListFromFile()

            // Загружаем аннотации
            loadAnnotationsFromFile()

            let thumbnailsDestinationURL = projectFolderURL.appendingPathComponent("thumbnails")
            self.isLoadingThumbnails = true
            self.loadingProgress = 0.0

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let thumbnailFiles = try FileManager.default.contentsOfDirectory(at: thumbnailsDestinationURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    let totalCount = thumbnailFiles.count
                    var loadedCount = 0
                    var loadedThumbnails: [URL] = []

                    for url in thumbnailFiles {
                        loadedThumbnails.append(url)
                        loadedCount += 1
                        let progress = Double(loadedCount) / Double(totalCount)
                        DispatchQueue.main.async {
                            self.loadingProgress = progress
                        }
                    }

                    DispatchQueue.main.async {
                        self.thumbnailURLs = loadedThumbnails
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
    }

    func loadImages(from url: URL) {
        // Загрузка изображений из указанной папки
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
        // Создание миниатюр для изображений
        guard let projectURL = projectURL else { return }

        isCreatingThumbnails = true
        creationProgress = 0.0

        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnailFolderURL = projectURL.appendingPathComponent("thumbnails")
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
        // Загрузка миниатюр из папки
        guard let projectURL = projectURL else { return }

        isLoadingThumbnails = true
        loadingProgress = 0.0

        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnailFolderURL = projectURL.appendingPathComponent("thumbnails")
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
        // Сохранение аннотаций в файл
        guard let projectURL = projectURL else { return }

        let annotationsURL = projectURL.appendingPathComponent("annotations.json")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(annotations)
            try data.write(to: annotationsURL)
        } catch {
            print("Ошибка при сохранении аннотаций: \(error.localizedDescription)")
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
        // Получение оригинального URL изображения по URL миниатюры
        guard let projectURL = projectURL else { return thumbnailURL }
        let imageURL = projectURL.appendingPathComponent(thumbnailURL.lastPathComponent)
        return imageURL
    }

    // Управление классами

    func addClass() {
        let trimmedClassName = newClassName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedClassName.isEmpty && !classList.contains(trimmedClassName) {
            classList.append(trimmedClassName)
            newClassName = ""
            saveClassListToFile() // Сохраняем список классов

            // Если ни один класс не выбран, выбираем только что добавленный
            if selectedClass == nil {
                selectedClass = trimmedClassName
            }
        }
    }

    // Функция для удаления класса
    func deleteClass(at offsets: IndexSet) {
        classList.remove(atOffsets: offsets)
        saveClassListToFile() // Сохраняем список классов
    }

    
    func loadClassListFromFile() {
        do {
            if let projectURL = self.projectURL {
                let classesFileURL = projectURL.appendingPathComponent("classes.json")
                let jsonData = try Data(contentsOf: classesFileURL)
                let decoder = JSONDecoder()
                self.classList = try decoder.decode([String].self, from: jsonData)
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

#Preview {
    ContentView()
}
