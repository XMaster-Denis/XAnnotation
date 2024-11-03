//
//  ImageThumbnailsView.swift
//  XAnnotation
//
//  Created by XMaster on 25.09.24.
//
import SwiftUI

struct ImageThumbnailsView: View {
    
    @EnvironmentObject var annotationsData: AnnotationViewModel
    @EnvironmentObject var projectData: ProjectDataViewModel
    @EnvironmentObject var imageThumbnailsData: ImageThumbnailsViewModel
    
    var body: some View {
        
        VStack {
            // Список папок
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    ForEach(projectData.foldersInProject, id: \.self) { folderName in
                        Button(action: {
                            projectData.selectedFolder = folderName
                            imageThumbnailsData.loadImagesForSelectedFolder()
                            
                        }) {
                            Text(folderName)
                                .bold()
                                .cornerRadius(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(projectData.selectedFolder == folderName ? Color.blue.opacity(1) : Color.clear)
                    }
                }
            }
            .frame(maxHeight: 200)
            
            // Кнопка для добавления новой папки
            Button(action: imageThumbnailsData.addImageFolder) {
                Text("Добавить папку с изображениями")
            }
            
            // Отображение миниатюр изображений
            ScrollView(.vertical) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(imageThumbnailsData.thumbnailURLs, id: \.self) { url in
                        ZStack (alignment: .topTrailing) {
                            
                            Button(action: {
                                projectData.selectedImageURL = imageThumbnailsData.getImageURL(forThumbnailURL: url)

                                projectData.saveProjectSettings()
                            }) {
                                AsyncImageView(url: url, size: CGSize(width: 120, height: 120))
                                    .padding(2)
                                    .border(projectData.selectedImageURL == imageThumbnailsData.getImageURL(forThumbnailURL: url) ? Color.blue : Color.clear, width: 2)
                                
                            }
                            .buttonStyle(PlainButtonStyle())
                            let numberOfAnnotations: Int = annotationsData.numberOfAnnotations(for: url)
                            Text("\(numberOfAnnotations)")
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                            
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.green)
                                )
                                .foregroundColor(.red)
                                .font(.title)
                                .offset(x: -5, y: 5)
                            
                            
                        }
                    }
                }
            }
        }
        .frame(minWidth: 100, maxWidth: 150)
        
    }
}
