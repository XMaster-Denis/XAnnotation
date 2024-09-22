//
//  NSImage.swift
//  XAnnotation
//
//  Created by XMaster on 20.09.24.
//
import SwiftUI

extension NSImage {
    func resizeMaintainingAspectRatio(to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    func savePNG(to url: URL) {
        guard let tiffData = self.tiffRepresentation else { return }
        guard let bitmap = NSBitmapImageRep(data: tiffData) else { return }
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return }

        do {
            try data.write(to: url)
        } catch {
            print("Ошибка при сохранении изображения: \(error.localizedDescription)")
        }
    }
    
    var pixelSize: CGSize? {
        guard let bitmapRep = representations.first as? NSBitmapImageRep else { return nil }
        return CGSize(width: bitmapRep.pixelsWide, height: bitmapRep.pixelsHigh)
    }
}
