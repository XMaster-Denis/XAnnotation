import SwiftUI

struct StaticImageView: View {
    
    @EnvironmentObject var projectData: ProjectDataViewModel
    
    var body: some View {
        GeometryReader { containerGeometry in
            let containerSize = containerGeometry.size
            ZStack {
                if let imageURL = projectData.selectedImageURL, let nsImage = NSImage(contentsOf: imageURL),
                   let pixelSize = nsImage.pixelSize  {
                    // Вычисляем аспектное соотношение изображения
                    
                    
                    // Вычисляем аспектное соотношение изображения
                    let imageAspectRatio = pixelSize.width / pixelSize.height
                    
                    // Вычисляем размер изображения и его позицию
                    let imageSize: CGSize = (containerSize.width / containerSize.height > imageAspectRatio)
                    ? CGSize(width: containerSize.height * imageAspectRatio, height: containerSize.height)
                    : CGSize(width: containerSize.width, height: containerSize.width / imageAspectRatio)
                    
                    let imageOrigin = CGPoint(
                        x: (containerSize.width - imageSize.width) / 2,
                        y: (containerSize.height - imageSize.height) / 2
                    )
                    
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                    СrossView(imageOrigin: imageOrigin, imageSize: imageSize)
                    
                    
                } else {
                    Text("Failed to upload image")
                        .foregroundColor(.red)
                }
            }
            .frame(width: containerSize.width, height: containerSize.height)
        }
    }
}

