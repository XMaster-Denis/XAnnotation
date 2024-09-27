import SwiftUI

struct AnnotationView: View {

    
    @State private var currentRect: CGRect = .zero
    @State private var isDrawing = false
    @State private var selectedAnnotationID: UUID? = nil
    @State private var hoverLocation: CGPoint = .zero
    @State private var isHovering = false
    
    @EnvironmentObject var annotationsData: AnnotationViewModel
    @EnvironmentObject var projectData: ProjectDataViewModel
    @EnvironmentObject var classData: ClassDataViewModel
    @EnvironmentObject var krestData: KrestViewModel
    
    
    var body: some View {
        
        
        GeometryReader { containerGeometry in
            let containerSize = containerGeometry.size
            //let imageURL2 = projectData.projectURL!.appendingPathComponent("thumbnails").appendingPathComponent(projectData.selectedFolder!).appendingPathComponent(projectData.selectedImageURL!.lastPathComponent)
            ZStack {
                if let imageURL = projectData.selectedImageURL, let nsImage = NSImage(contentsOf: imageURL),
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
                    
                    //Image(nsImage: nsImage)
                    Rectangle()
                        .fill(.opacity(0.01))
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
                                        if let selectedClass =  classData.selectedClass {
                                            annotationsData.addAnnotation(imageScale: imageScale, imageSize: imageSize, currentRect: currentRect, selectedClass: selectedClass)
                                        }
                                    } else {
                                        print("Аннотация слишком маленькая и не будет сохранена.")
                                    }
                                    
                                    currentRect = .zero
                                }
                        )
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                krestData.hoverLocation = location
                                krestData.isHovering = true
                            case .ended:
                                krestData.isHovering = false
                            }
                        }
                        .overlay {
                            if isHovering {
                                Text("\(pixelSize)")
                               // Text("x: \(hoverLocation.x), y: \(hoverLocation.y)")
                                    .foregroundColor(.green)
                                    .font(.title)
                            }
                        }
                    
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
                            ), lineWidth: 3)
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
                    ForEach(annotationsData.currentImageAnnotations) { annotation in
                        if let classData = classData.classList.first(where: { $0.name == annotation.label }) {
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
                            ResizableHandle(position: .topLeft,  currentRect: annotationRect, imageOrigin: imageOrigin, onDrag: { newPosition in
                                annotationsData.resizeAnnotation(annotation: annotation, handle: .topLeft, newPosition: newPosition, imageScale: imageScale, imageSize: imageSize)
                            })
                            
                            ResizableHandle(position: .topRight, currentRect: annotationRect, imageOrigin: imageOrigin, onDrag: { newPosition in
                                annotationsData.resizeAnnotation(annotation: annotation, handle: .topRight, newPosition: newPosition, imageScale: imageScale, imageSize: imageSize)
                            })
                            
                            ResizableHandle(position: .bottomLeft, currentRect: annotationRect, imageOrigin: imageOrigin, onDrag: { newPosition in
                                annotationsData.resizeAnnotation(annotation: annotation, handle: .bottomLeft, newPosition: newPosition, imageScale: imageScale, imageSize: imageSize)
                            })
                            
                            ResizableHandle(position: .bottomRight, currentRect: annotationRect, imageOrigin: imageOrigin, onDrag: { newPosition in
                                annotationsData.resizeAnnotation(annotation: annotation, handle: .bottomRight, newPosition: newPosition, imageScale: imageScale, imageSize: imageSize)
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
    
    
}


//struct AnnotationView_Previews: PreviewProvider {
//    static var previews: some View {
//        AnnotationView(
//            imageURL: URL(string: "path/to/image.jpg")!,
//            annotations: .constant([]),
//            classList: .constant([]),
//            selectedClass: .constant(nil),
//            projectURL: .constant(nil),
//            saveAnnotations: {}
//        )
//    }
//}

