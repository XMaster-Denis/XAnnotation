//
//  ClassRowView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

struct ClassRowView: View {
    @Binding var currentClassData: ClassData

    var saveClassListToFile: () -> Void

    @State  var editingClassID: UUID? = nil
    @State  var editedClassName: String = ""
    @State  var selectedColor: Color = .white
    
    // Для отображения Alert
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @EnvironmentObject var projectData: ProjectDataViewModel
    @EnvironmentObject var classData: ClassDataViewModel
    @EnvironmentObject var annotationsData: AnnotationViewModel
    
    var isPopoverPresented: Binding<Bool> {
        Binding<Bool>(
            get: { editingClassID == currentClassData.id },
            set: { newValue in
                if !newValue {
                    editingClassID = nil
                }
            }
        )
    }
    
    var body: some View {
        
        HStack {
            Text(currentClassData.name)
                .foregroundColor(classData.selectedClass?.id == currentClassData.id ? Color.red : Color.primary)
                .bold(classData.selectedClass?.id == currentClassData.id)
            
            Spacer()
            
            // Цветной прямоугольник
            Rectangle()
                .fill(currentClassData.color.toColor())
                .frame(width: 30, height: 20)
                .cornerRadius(3)
                .onTapGesture {
                    editingClassID = currentClassData.id
                    editedClassName = currentClassData.name // Инициализируем редактируемое имя
                }
                .popover(isPresented: isPopoverPresented) {
                    VStack {
                        ColorPicker("Выберите цвет", selection: $selectedColor)
                        
                        // Поле для редактирования имени класса
                        TextField("Новое имя класса", text: $editedClassName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.top)

                        
                        Button("Сохранить изменения") {
                            saveChanges()
                        }
                        .disabled(editedClassName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.top)
                        
                        Button("Закрыть") {
                            editingClassID = nil
                            editedClassName = ""
                        }
                        .padding(.top)
                    }
                    .padding()
                    .frame(width: 300, height: 300)
                    
                    .onAppear {
                        if editingClassID == currentClassData.id {
                           // editedClassName = classData.name
                            selectedColor = currentClassData.color.toColor()
                        }
                    }
                }
        }
        .contextMenu {
            Button("Редактировать имя") {
                editingClassID = currentClassData.id
                editedClassName = currentClassData.name
            }
            Button("Удалить") {
                deleteClass()
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Функции
    
    private func saveChanges() {
        let trimmedName = editedClassName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let oldClassName = currentClassData.name
        
        // 1. Проверка на пустое имя
        if trimmedName.isEmpty {
            alertMessage = "Имя класса не может быть пустым."
            showAlert = true
            return
        }
        
        // 2. Проверка на уникальность имени
        let nameExists = classData.classList.contains { $0.name == trimmedName && $0.id != currentClassData.id }
        if nameExists {
            alertMessage = "Имя класса уже существует."
            showAlert = true
            return
        }
        
        // 3. Поиск индекса класса для редактирования
        guard let index = classData.classList.firstIndex(where: { $0.id == currentClassData.id }) else {
            alertMessage = "Класс не найден."
            showAlert = true
            return
        }
        
        // Обновляем аннотации
       // updateAnnotations(from: oldClassName, to: trimmedName)
        
        // 4. Обновление имени класса
        classData.classList[index].name = trimmedName
        currentClassData.color = ColorData.fromColor(selectedColor)
        saveClassListToFile()
        annotationsData.updateAnnotations(from: oldClassName, to: trimmedName)
    //    if classData.selectedClass == nil {
        classData.selectedClass = classData.classList[index]
   //     }
        // Закрываем системную панель выбора цвета
        NSColorPanel.shared.close()
        editedClassName = ""
        editingClassID = nil
    }
    
    private func deleteClass() {
        if let index = classData.classList.firstIndex(where: { $0.id == currentClassData.id }) {
            classData.classList.remove(at: index)
            saveClassListToFile()
        }
    }
}


