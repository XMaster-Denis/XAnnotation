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
    @State private var selectedAnnotationID: UUID? = nil
    
    var body: some View {
        GeometryReader { containerGeometry in
            let containerSize = containerGeometry.size
            
            ZStack {
                if let nsImage = NSImage(contentsOf: imageURL),
                   let pixelSize = nsImage.pixelSize  {
                    // Вычисляем аспектное соотношение изображения
                    //let imageAspectRatio = nsImage.size.width / nsImage.size.height
                    
                    // Вычисляем аспектное соотношение изображения
                    let imageAspectRatio = pixelSize.width / pixelSize.height
                    
                    // Вычисляем размер изображения и его позицию
                    let imageSize: CGSize = (containerSize.width / containerSize.height > imageAspectRatio)
                    ? CGSize(width: containerSize.height * imageAspectRatio, height: containerSize.height)
                    : CGSize(width: containerSize.width, height: containerSize.width / imageAspectRatio)
                    
                    let imageOrigin = CGPoint(
                        x: (containerSize.width - imageSize.width) / 2,
                        y: (containerSize.height - imageSize.height) / 2
                    )
                    
                    // Вычисляем масштаб изображения
                    //let imageScale = nsImage.size.width / imageSize.width
                    let imageScale = pixelSize.width / imageSize.width
                    
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize.width, height: imageSize.height)
                        .position(
                            x: imageOrigin.x + imageSize.width / 2,
                            y: imageOrigin.y + imageSize.height / 2
                        )
                        .gesture(
                            DragGesture(minimumDistance: 2)
                                .onChanged { value in
                                    let location = CGPoint(
                                        x: value.location.x - imageOrigin.x,
                                        y: value.location.y - imageOrigin.y
                                    )
                                    guard location.x >= 0, location.y >= 0,
                                          location.x <= imageSize.width, location.y <= imageSize.height else {
                                        return
                                    }
                                    print("onChanged")
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
                            

                                    // Нормализация currentRect для обеспечения положительных размеров
                                    let normalizedRect = currentRect.standardized
                          
                                    currentRect = .zero
                                    currentRect = normalizedRect

                                    // Дополнительная проверка на минимальные размеры (опционально)
                                    let minimumSize: CGFloat = 10
                                    if normalizedRect.width >= minimumSize && normalizedRect.height >= minimumSize {
                                        addAnnotation(imageScale: imageScale, imageSize: imageSize)
                                    } else {
                                        print("Аннотация слишком маленькая и не будет сохранена.")
                                    }

                                    currentRect = .zero
                                }
                        )
                    
                    // Рисуем текущий прямоугольник аннотации
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
                    
                    // Рисуем сохраненные аннотации
                    ForEach(currentImageAnnotations) { annotation in
                        if let classData = classList.first(where: { $0.name == annotation.label }) {
                            let annotationRect = CGRect(
                                x: annotation.coordinates.x / Double(imageScale) + imageOrigin.x,
                                y: annotation.coordinates.y / Double(imageScale) + imageOrigin.y,
                                width: annotation.coordinates.width / Double(imageScale),
                                height: annotation.coordinates.height / Double(imageScale)
                            )
                            
                            Rectangle()
                                .stroke(classData.color.toColor(), lineWidth: 5)
                                .frame(width: annotationRect.width, height: annotationRect.height)
                                .position(
                                    x: annotationRect.midX,
                                    y: annotationRect.midY
                                )
                                .onTapGesture {
                                    selectedAnnotationID = annotation.id
                                }
                            
                            
                            // Если аннотация выбрана, отображаем маркеры
                         //   if selectedAnnotationID != annotation.id {
                                // Размер маркера
                               
                                
                                
                                // Добавляем маркеры
                                ResizableHandle(position: .topLeft,  currentRect: annotationRect, imageOrigin: imageOrigin, saveAnnotations: saveAnnotations, onDrag: { newPosition in
                                    resizeAnnotation(annotation: annotation, handle: .topLeft, newPosition: newPosition, imageScale: imageScale, imageSize: imageSize)
                                })
                                
                                ResizableHandle(position: .topRight, currentRect: annotationRect, imageOrigin: imageOrigin, saveAnnotations: saveAnnotations, onDrag: { newPosition in
                                    resizeAnnotation(annotation: annotation, handle: .topRight, newPosition: newPosition, imageScale: imageScale, imageSize: imageSize)
                                })
                                
                                ResizableHandle(position: .bottomLeft, currentRect: annotationRect, imageOrigin: imageOrigin, saveAnnotations: saveAnnotations, onDrag: { newPosition in
                                    resizeAnnotation(annotation: annotation, handle: .bottomLeft, newPosition: newPosition, imageScale: imageScale, imageSize: imageSize)
                                })
                                
                                ResizableHandle(position: .bottomRight, currentRect: annotationRect, imageOrigin: imageOrigin, saveAnnotations: saveAnnotations, onDrag: { newPosition in
                                    resizeAnnotation(annotation: annotation, handle: .bottomRight, newPosition: newPosition, imageScale: imageScale, imageSize: imageSize)
                                })
                           // }
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
    
    /// Добавляет новую аннотацию
    func addAnnotation(imageScale: CGFloat, imageSize: CGSize) {
        guard let selectedClass = selectedClass else {
            // Если класс не выбран, не сохраняем аннотацию
            print("Класс не выбран. Пожалуйста, выберите класс перед аннотированием.")
            return
        }

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
        
        // Сохраняем аннотации
        saveAnnotations()
    }
    
    /// Ресайзит аннотацию
    func resizeAnnotation(annotation: Annotation, handle: ResizableHandle.HandlePosition, newPosition: CGPoint, imageScale: CGFloat, imageSize: CGSize) {
        guard let projectURL = self.projectURL else {
            print("Проект не установлен.")
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
    
}


struct AnnotationView_Previews: PreviewProvider {
    static var previews: some View {
        AnnotationView(
            imageURL: URL(string: "path/to/image.jpg")!,
            annotations: .constant([]),
            classList: .constant([]),
            selectedClass: .constant(nil),
            projectURL: .constant(nil),
            saveAnnotations: {}
        )
    }
}

