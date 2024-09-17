//
//  Annotation.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import Foundation

struct AnnotationData: Codable, Hashable {
    var image: String
    var annotations: [Annotation]
}

struct Annotation: Codable, Hashable {
    var label: String
    var coordinates: Coordinates
}

struct Coordinates: Codable, Hashable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
}
