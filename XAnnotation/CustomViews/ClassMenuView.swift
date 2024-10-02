//
//  ClassMenuView.swift
//  XAnnotation
//
//  Created by XMaster on 02.10.24.
//
import SwiftUI

struct ClassMenuView: View   {
    
    var annotation: Annotation
    @EnvironmentObject var classData: ClassDataViewModel
    @EnvironmentObject var annotationsData: AnnotationViewModel
    
    var body: some View {
        ForEach(classData.classList) { classItem2 in
            Button(classItem2.name) {
                annotationsData.updateAnnotationClass(annotation: annotation, newClassName: classItem2.name)
            }
        }
    }
}
