//
//  ClassListView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

struct ClassListView: View {
    
    @EnvironmentObject var projectData: ProjectDataViewModel
    @EnvironmentObject var classData: ClassDataViewModel
    @EnvironmentObject var annotationsData: AnnotationViewModel
    
    @State private var newClassName: String = ""
    //@State private var selectedClass: ClassData?
    
    var body: some View {
        
        Text("List of classes:")
            .font(.headline)
        
        List(selection: $classData.selectedClass) {
            ForEach($classData.classList) { $classData in
                ClassRowView(
                    currentClassData: $classData,
                    saveClassListToFile: saveClassListToFile
                )
                .tag(classData)
            }
            .onDelete(perform: deleteClassAt)
        }
        //            .onChange(of: selectedClass) { oldValue, newValue in
        //                classData.selectedClass = newValue
        //            }
        
        VStack {
            TextField("Class name", text: $newClassName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action: addClass) {
                Text("Add class")
            }
            .disabled(newClassName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        
        Spacer()
        
        if classData.selectedClass == nil {
            Text("Please select a class to annotate.")
                .foregroundColor(.red)
        } else {
            Text("Currently selected class: \(classData.selectedClass!.name)")
                .foregroundColor(.green)
        }
        
    }
    
    // MARK: - Функции
    
    private func addClass() {
        let trimmedClassName = newClassName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedClassName.isEmpty && !classData.classList.contains(where: { $0.name == trimmedClassName }) {
            // Генерируем случайный цвет
            let randomColor = ColorData(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1))
            
            // Создаем новый класс с цветом
            let newClass = ClassData(name: trimmedClassName, color: randomColor)
            classData.classList.append(newClass)
            
            // Очищаем поле для ввода
            newClassName = ""
            
            // Сохраняем список классов
            saveClassListToFile()
            
            // Если ни один класс не выбран, выбираем только что добавленный
            if classData.selectedClass == nil {
                classData.selectedClass = newClass
            }
        }
    }
    
    // Функция сохранения списка классов в файл
    func saveClassListToFile() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(classData.classList)
            if let projectURL = projectData.projectURL {
                let classesFileURL = projectURL.appendingPathComponent("classes.json")
                try jsonData.write(to: classesFileURL)
                printLog("Class list saved at: \(classesFileURL.path)")
            }
        } catch {
            printLog("Error saving class list: \(error.localizedDescription)")
        }
    }
    
    private func deleteClassAt(offsets: IndexSet) {
        classData.classList.remove(atOffsets: offsets)
        saveClassListToFile()
    }
}


