//
//  Annotation.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import Foundation

struct AnnotationData: Codable, Identifiable {
    var id: UUID = UUID()
    let imagePath: String // Путь к изображению относительно корня проекта
    var annotations: [Annotation]
}

struct Annotation: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var label: String
    var coordinates: Coordinates
}

struct Coordinates: Codable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
