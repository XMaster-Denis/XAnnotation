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

@propertyWrapper
struct RoundedToTenths: Codable, Hashable {
    private var value: Double

    var wrappedValue: Double {
        get { value }
        set { value = (newValue * 10).rounded() / 10 }
    }

    init(wrappedValue: Double) {
        self.value = (wrappedValue * 10).rounded() / 10
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValue = try container.decode(Double.self)
        self.value = (decodedValue * 10).rounded() / 10
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode((value * 10).rounded() / 10)
    }
}

struct Coordinates: Codable, Hashable {
    @RoundedToTenths var x: Double
    @RoundedToTenths var y: Double
    @RoundedToTenths var width: Double
    @RoundedToTenths var height: Double
}
