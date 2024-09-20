//
//  ClassListView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

struct ClassListView: View {
    @Binding var classList: [ClassData]
    @Binding var selectedClass: ClassData?
    var saveClassListToFile: () -> Void
    var saveProjectSettings: () -> Void
    
    @State private var newClassName: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Список классов:")
                .font(.headline)
            
            List(selection: $selectedClass) {
                ForEach(classList) { classData in
                    ClassRowView(
                        classData: classData,
                        selectedClass: $selectedClass,
                        classList: $classList,
                        saveClassListToFile: saveClassListToFile,
                        saveProjectSettings: saveProjectSettings
                    )
                    .tag(classData)
                }
                .onDelete(perform: deleteClassAt)
            }
            
            VStack {
                TextField("Добавить класс", text: $newClassName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: addClass) {
                    Text("Добавить")
                }
                .disabled(newClassName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Add 2 classes") {
                    newClassName = "Red"
                    addClass()
                    newClassName = "Blue"
                    addClass()
                    newClassName = ""
                }
            }
            .padding()
            
            if selectedClass == nil {
                Text("Пожалуйста, выберите класс для аннотирования.")
                    .foregroundColor(.red)
            } else {
                Text("Текущий выбранный класс: \(selectedClass!.name)")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(width: 250)
    }
    
    // MARK: - Функции
    
    private func addClass() {
        let trimmedClassName = newClassName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedClassName.isEmpty && !classList.contains(where: { $0.name == trimmedClassName }) {
            // Генерируем случайный цвет
            let randomColor = ColorData(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1))
            
            // Создаем новый класс с цветом
            let newClass = ClassData(name: trimmedClassName, color: randomColor)
            classList.append(newClass)
            
            // Очищаем поле для ввода
            newClassName = ""
            
            // Сохраняем список классов
            saveClassListToFile()
            
            // Если ни один класс не выбран, выбираем только что добавленный
            if selectedClass == nil {
                selectedClass = newClass
            }
        }
    }
    
    private func deleteClassAt(offsets: IndexSet) {
        classList.remove(atOffsets: offsets)
        saveClassListToFile()
    }
}

struct ClassListView_Previews: PreviewProvider {
    static var previews: some View {
        ClassListView(
            classList: .constant([]),
            selectedClass: .constant(nil),
            saveClassListToFile: {},
            saveProjectSettings: {}
        )
    }
}
