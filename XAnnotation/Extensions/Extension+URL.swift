//
//  URL.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import AppKit

extension URL {
    var isImageFile: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"]
        return imageExtensions.contains(self.pathExtension.lowercased())
    }
    
    var width: CGFloat {
        guard let image = NSImage(contentsOf: self) else { return 0 }
        return image.size.width
    }
    
    var height: CGFloat {
        guard let image = NSImage(contentsOf: self) else { return 0 }
        return image.size.height
    }
}
