//
//  NSImage.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import AppKit

extension NSImage {
    static func load(from url: URL) -> NSImage? {
        return NSImage(contentsOf: url)
    }
}
