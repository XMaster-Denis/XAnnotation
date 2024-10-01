//
//  XAnnotationApp.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

@main
struct XAnnotationApp: App {

    @StateObject var projectData: ProjectDataViewModel = ProjectDataViewModel.init()
    @StateObject var krestViewModel: СrossViewModel = СrossViewModel.init()
    @StateObject var classData: ClassDataViewModel = ClassDataViewModel.init(projectData: ProjectDataViewModel())
    @StateObject var annotationsData: AnnotationViewModel = AnnotationViewModel.init(projectData: ProjectDataViewModel())
    @StateObject var imageThumbnailsData: ImageThumbnailsViewModel = ImageThumbnailsViewModel.init(projectData: ProjectDataViewModel())
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(annotationsData)
                .environmentObject(krestViewModel)
                .environmentObject(projectData)
                .environmentObject(classData)
                .environmentObject(imageThumbnailsData)
                .onAppear {
                        annotationsData.projectData = projectData
                        classData.projectData = projectData
                        imageThumbnailsData.projectData = projectData
                }
            
        }
    }
}
