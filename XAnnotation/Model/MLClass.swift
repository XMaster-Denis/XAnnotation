//
//  MLClass.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI
import AppKit // Для использования NSColor

struct ClassData: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    var color: ColorData
    
    init(id: UUID = UUID(), name: String, color: ColorData) {
        self.id = id
        self.name = name
        self.color = color
    }
}

struct ColorData: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    
    // Метод для создания SwiftUI Color
    func toColor() -> Color {
        return Color(red: red, green: green, blue: blue)
    }
    
    // Метод для создания ColorData из SwiftUI Color
    static func fromColor(_ color: Color) -> ColorData {
        let nsColor = NSColor(color) // Используем NSColor для macOS
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        return ColorData(red: Double(red), green: Double(green), blue: Double(blue))
    }
}
