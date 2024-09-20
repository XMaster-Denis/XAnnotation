//
//  AnnotationView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//


import SwiftUI

struct AnnotationView: View {
    let imageURL: URL
    @Binding var annotations: [AnnotationData]
    @Binding var classList: [ClassData]
    @Binding var selectedClass: ClassData?
    @Binding var projectURL: URL?
    var saveAnnotations: () -> Void

    @State private var currentRect: CGRect = .zero
    @State private var isDrawing = false

    var body: some View {
        GeometryReader { containerGeometry in
            let containerSize = containerGeometry.size

            ZStack {
                if let nsImage = NSImage(contentsOf: imageURL) {
                    // Compute imageAspectRatio
                    let imageAspectRatio = nsImage.size.width / nsImage.size.height

                    // Compute imageSize and imageOrigin using a ternary operator
                    let imageSize: CGSize = (containerSize.width / containerSize.height > imageAspectRatio)
                        ? CGSize(width: containerSize.height * imageAspectRatio, height: containerSize.height)
                        : CGSize(width: containerSize.width, height: containerSize.width / imageAspectRatio)

                    let imageOrigin = CGPoint(
                        x: (containerSize.width - imageSize.width) / 2,
                        y: (containerSize.height - imageSize.height) / 2
                    )

                    // Compute imageScale
                    let imageScale = nsImage.size.width / imageSize.width

                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize.width, height: imageSize.height)
                        .position(
                            x: imageOrigin.x + imageSize.width / 2,
                            y: imageOrigin.y + imageSize.height / 2
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let location = CGPoint(
                                        x: value.location.x - imageOrigin.x,
                                        y: value.location.y - imageOrigin.y
                                    )
                                    guard location.x >= 0, location.y >= 0,
                                          location.x <= imageSize.width, location.y <= imageSize.height else {
                                        return
                                    }
                                    if !isDrawing {
                                        isDrawing = true
                                        currentRect.origin = location
                                        currentRect.size = CGSize(width: 0, height: 0)
                                    }
                                    currentRect.size = CGSize(
                                        width: location.x - currentRect.origin.x,
                                        height: location.y - currentRect.origin.y
                                    )
                                }
                                .onEnded { _ in
                                    isDrawing = false
                                    addAnnotation(imageScale: imageScale, imageSize: imageSize)
                                    currentRect = .zero
                                }
                        )

                    // Drawing current rectangle
                    if isDrawing {
                        Rectangle()
                            .stroke(LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white, location: 0.0),
                                    .init(color: .blue, location: 0.01),
                                    .init(color: .orange, location: 0.05),
                                    .init(color: .yellow, location: 0.1),
                                    .init(color: .green, location: 0.15),
                                    .init(color: .blue, location: 0.2),
                                    .init(color: .purple, location: 0.25),
                                    .init(color: .red, location: 0.3),
                                    .init(color: .orange, location: 0.35),
                                    .init(color: .yellow, location: 0.4),
                                    .init(color: .green, location: 0.45),
                                    .init(color: .blue, location: 0.5),
                                    .init(color: .red, location: 0.55),
                                    .init(color: .orange, location: 0.6),
                                    .init(color: .yellow, location: 0.65),
                                    .init(color: .green, location: 0.7),
                                    .init(color: .blue, location: 0.75),
                                    .init(color: .purple, location: 0.8),
                                    .init(color: .red, location: 0.85),
                                    .init(color: .orange, location: 0.9),
                                    .init(color: .yellow, location: 0.95),
                                    .init(color: .green, location: 0.98),
                                    .init(color: .blue, location: 1.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 2)
                            .frame(
                                width: abs(currentRect.size.width),
                                height: abs(currentRect.size.height)
                            )
                            .position(
                                x: currentRect.origin.x + currentRect.size.width / 2 + imageOrigin.x,
                                y: currentRect.origin.y + currentRect.size.height / 2 + imageOrigin.y
                            )
                    }

                    // Drawing saved annotations
                    ForEach(currentImageAnnotations) { annotation in
                        if let classData = classList.first(where: { $0.name == annotation.label }) {
                            let annotationRect = CGRect(
                                x: annotation.coordinates.x / Double(imageScale),
                                y: annotation.coordinates.y / Double(imageScale),
                                width: annotation.coordinates.width / Double(imageScale),
                                height: annotation.coordinates.height / Double(imageScale)
                            )

                            Rectangle()
                                .stroke(classData.color.toColor(), lineWidth: 3)
                                .frame(width: annotationRect.width, height: annotationRect.height)
                                .position(
                                    x: annotationRect.midX + imageOrigin.x,
                                    y: annotationRect.midY + imageOrigin.y
                                )
                        } else {
                            // Если класс не найден, используем стандартный цвет
                            let annotationRect = CGRect(
                                x: annotation.coordinates.x / Double(imageScale),
                                y: annotation.coordinates.y / Double(imageScale),
                                width: annotation.coordinates.width / Double(imageScale),
                                height: annotation.coordinates.height / Double(imageScale)
                            )

                            Rectangle()
                                .stroke(Color.blue, lineWidth: 3)
                                .frame(width: annotationRect.width, height: annotationRect.height)
                                .position(
                                    x: annotationRect.midX + imageOrigin.x,
                                    y: annotationRect.midY + imageOrigin.y
                                )
                        }
                    }

                    
                } else {
                    Text("Не удалось загрузить изображение")
                        .foregroundColor(.red)
                        .frame(width: containerSize.width, height: containerSize.height)
                }
            }
            .frame(width: containerSize.width, height: containerSize.height)
        }
    }

    /// Фильтрует аннотации для текущего изображения
    var currentImageAnnotations: [Annotation] {
        // Получаем относительный путь к изображению
        guard let projectURL = self.projectURL else {
            print("Проект не установлен.")
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



//    /// Добавляет новую аннотацию
//    func addAnnotation(imageScale: CGFloat) {
//        guard let selectedClass = selectedClass else {
//            // Если класс не выбран, не сохраняем аннотацию
//            print("Класс не выбран. Пожалуйста, выберите класс перед аннотированием.")
//            return
//        }
//
//        let normalizedX = currentRect.origin.x * imageScale
//        let normalizedY = currentRect.origin.y * imageScale
//        let normalizedWidth = currentRect.size.width * imageScale
//        let normalizedHeight = currentRect.size.height * imageScale
//
//        let newAnnotation = AnnotationData(
//            imageURL: imageURL,
//            className: selectedClass.name,
//            boundingBox: CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
//        )
//
//        annotations.append(newAnnotation)
//
//        // Сохраняем аннотации
//        saveAnnotations()
//    }
    
    
    /// Добавляет новую аннотацию
    func addAnnotation(imageScale: CGFloat, imageSize: CGSize) {
        guard let selectedClass = selectedClass else {
            // Если класс не выбран, не сохраняем аннотацию
            print("Класс не выбран. Пожалуйста, выберите класс перед аннотированием.")
            return
        }

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
        
        

            guard let projectURL = self.projectURL else {
                print("Проект не установлен.")
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

//        // Найти существующую запись для изображения и добавить аннотацию
//        if let index = annotations.firstIndex(where: { $0.imagePath == imageURL.lastPathComponent }) {
//            annotations[index].annotations.append(newAnnotation)
//        } else {
//            // Если запись не существует, добавить новую
//            let annotationData = AnnotationData(
//                imagePath: imageURL.lastPathComponent,
//                annotations: [newAnnotation]
//            )
//            annotations.append(annotationData)
//        }

        // Сохраняем аннотации
        saveAnnotations()
    }
}
