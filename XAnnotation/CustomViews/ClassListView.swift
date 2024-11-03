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
        
        Text("Список классов:")
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
            Text("Пожалуйста, выберите класс для аннотирования.")
                .foregroundColor(.red)
        } else {
            Text("Текущий выбранный класс: \(classData.selectedClass!.name)")
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
                printLog("Список классов сохранен по пути: \(classesFileURL.path)")
            }
        } catch {
            printLog("Ошибка при сохранении списка классов: \(error.localizedDescription)")
        }
    }
    
    private func deleteClassAt(offsets: IndexSet) {
        classData.classList.remove(atOffsets: offsets)
        saveClassListToFile()
    }
}


