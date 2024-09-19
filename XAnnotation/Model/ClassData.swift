//
//  MLClass.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI
import AppKit // Для использования NSColor


struct ClassData: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var color: ColorData
}

struct ColorData: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
}

extension ColorData {
    func toColor() -> Color {
        return Color(red: red, green: green, blue: blue)
    }

    static func fromColor(_ color: Color) -> ColorData {
        let uiColor = NSColor(color)
        return ColorData(red: Double(uiColor.redComponent),
                         green: Double(uiColor.greenComponent),
                         blue: Double(uiColor.blueComponent))
    }
}
