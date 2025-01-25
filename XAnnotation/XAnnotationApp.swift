//
//  XAnnotationApp.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

@main
struct XAnnotationApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var projectData: ProjectDataViewModel = .init()
    @StateObject var settings: Settings = Settings.shared
    @StateObject var krestViewModel: СrossViewModel = СrossViewModel.shared
    @StateObject var classData: ClassDataViewModel = .init()
    @StateObject var annotationsData: AnnotationViewModel = .init()
    @StateObject var imageThumbnailsData: ImageThumbnailsViewModel = .init()
    @StateObject var exportViewModel: ExportViewModel = .init()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: settings.language.code))

                .environmentObject(settings)
                .environmentObject(exportViewModel)
                .environmentObject(annotationsData)
                .environmentObject(krestViewModel)
                .environmentObject(projectData)
                .environmentObject(classData)
                .environmentObject(imageThumbnailsData)
                //.environmentObject(logViewModel)
                .onAppear {
                    annotationsData.projectData = projectData
                    classData.projectData = projectData
                    imageThumbnailsData.projectData = projectData
                    exportViewModel.projectData = projectData
                    exportViewModel.annotationsData = annotationsData
                }
            
        }
        
        .commands {
            MenuCommands(imageThumbnailsData: imageThumbnailsData,
                         projectData: projectData)
        }
    }
    
    class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }
    }
}
