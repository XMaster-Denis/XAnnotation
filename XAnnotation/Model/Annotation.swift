//
//  Annotation.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import Foundation

//struct AnnotationData: Codable, Identifiable {
//    var id: UUID = UUID()
//    var imageURL: URL
//    var className: String
//    var boundingBox: CGRect
//
//}
//
//struct Annotation: Codable, Hashable {
//    var mlClass: ClassData
//    var coordinates: Coordinates
//}
//
//struct Coordinates: Codable, Hashable {
//    var x: CGFloat
//    var y: CGFloat
//    var width: CGFloat
//    var height: CGFloat
//}


struct AnnotationData: Codable, Identifiable {
    var id: UUID = UUID()
    var image: String // Имя изображения, например "0001.jpg"
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
