//
//  AsyncImageView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    private init() {}

    private var cache = NSCache<NSURL, NSImage>()

    func image(for url: NSURL) -> NSImage? {
        return cache.object(forKey: url)
    }

    func setImage(_ image: NSImage, for url: NSURL) {
        cache.setObject(image, forKey: url)
    }
}

struct AsyncImageView: View {
    let url: URL
    let size: CGSize

    @State private var image: NSImage? = nil

    var body: some View {
        ZStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
            } else {
                ProgressView()
                    .frame(width: size.width, height: size.height)
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    func loadImage() {
        if let cachedImage = ImageCache.shared.image(for: url as NSURL) {
            self.image = cachedImage
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let nsImage = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    ImageCache.shared.setImage(nsImage, for: self.url as NSURL)
                    self.image = nsImage
                }
            }
        }
    }
}
