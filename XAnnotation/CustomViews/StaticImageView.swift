import SwiftUI

struct StaticImageView: View {
    
    @EnvironmentObject var projectData: ProjectDataViewModel
    
    var body: some View {
        GeometryReader { containerGeometry in
            let containerSize = containerGeometry.size
            ZStack {
                if let imageURL = projectData.selectedImageURL, let nsImage = NSImage(contentsOf: imageURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("Не удалось загрузить изображение")
                        .foregroundColor(.red)
                }
            }
            .frame(width: containerSize.width, height: containerSize.height)
        }
    }
}

