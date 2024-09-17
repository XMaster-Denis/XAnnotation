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
    @Binding var classList: [String]
    @Binding var selectedClass: String?
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
                                    addAnnotation(imageScale: imageScale)
                                    currentRect = .zero
                                }
                        )

                    // Drawing current rectangle
                    if isDrawing {
                        Rectangle()
                            .stroke(Color.red, lineWidth: 2)
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
                    ForEach(currentImageAnnotations, id: \.self) { annotation in
                        let annotationRect = CGRect(
                            x: annotation.coordinates.x / imageScale,
                            y: annotation.coordinates.y / imageScale,
                            width: annotation.coordinates.width / imageScale,
                            height: annotation.coordinates.height / imageScale
                        )
                        Rectangle()
                            .stroke(Color.green, lineWidth: 2)
                            .frame(width: annotationRect.width, height: annotationRect.height)
                            .position(
                                x: annotationRect.midX + imageOrigin.x,
                                y: annotationRect.midY + imageOrigin.y
                            )
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

    var currentImageAnnotations: [Annotation] {
        if let annotationData = annotations.first(where: { $0.image == imageURL.lastPathComponent }) {
            return annotationData.annotations
        }
        return []
    }

    func addAnnotation(imageScale: CGFloat) {
        guard let selectedClass = selectedClass else {
            // Если класс не выбран, не сохраняем аннотацию
            print("Класс не выбран. Пожалуйста, выберите класс перед аннотированием.")
            return
        }

        let normalizedX = currentRect.origin.x * imageScale
        let normalizedY = currentRect.origin.y * imageScale
        let normalizedWidth = currentRect.size.width * imageScale
        let normalizedHeight = currentRect.size.height * imageScale

        let newAnnotation = Annotation(
            label: selectedClass,
            coordinates: Coordinates(
                x: normalizedX,
                y: normalizedY,
                width: normalizedWidth,
                height: normalizedHeight
            )
        )

        if let index = annotations.firstIndex(where: { $0.image == imageURL.lastPathComponent }) {
            annotations[index].annotations.append(newAnnotation)
        } else {
            let annotationData = AnnotationData(
                image: imageURL.lastPathComponent,
                annotations: [newAnnotation]
            )
            annotations.append(annotationData)
        }

        // Сохраняем аннотации
        saveAnnotations()
    }
}
