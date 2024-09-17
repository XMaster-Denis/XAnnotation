//
//  URL.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import AppKit

extension URL {
    var isImageFile: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff"]
        return imageExtensions.contains(self.pathExtension.lowercased())
    }
}
