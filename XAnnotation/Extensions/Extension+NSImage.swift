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
            printLog("Ошибка при сохранении изображения: \(error.localizedDescription)")
        }
    }
    
    var pixelSize: CGSize? {
        guard let bitmapRep = representations.first as? NSBitmapImageRep else { return nil }
        return CGSize(width: bitmapRep.pixelsWide, height: bitmapRep.pixelsHigh)
    }
    
    func rotated(by degrees : CGFloat) -> NSImage {
        var imageBounds = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let rotatedSize = AffineTransform(rotationByDegrees: degrees).transform(size)
        let newSize = CGSize(width: abs(rotatedSize.width), height: abs(rotatedSize.height))
        let rotatedImage = NSImage(size: newSize)

        imageBounds.origin = CGPoint(x: newSize.width / 2 - imageBounds.width / 2, y: newSize.height / 2 - imageBounds.height / 2)

        let otherTransform = NSAffineTransform()
        otherTransform.translateX(by: newSize.width / 2, yBy: newSize.height / 2)
        otherTransform.rotate(byDegrees: degrees)
        otherTransform.translateX(by: -newSize.width / 2, yBy: -newSize.height / 2)

        rotatedImage.lockFocus()
        otherTransform.concat()
        draw(in: imageBounds, from: CGRect.zero, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()

        return rotatedImage
    }
}
