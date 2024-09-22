//
//  ClassRowView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

struct ClassRowView: View {
    let classData: ClassData
    @Binding var selectedClass: ClassData?
    @Binding var classList: [ClassData]
    var saveClassListToFile: () -> Void
    var saveProjectSettings: () -> Void
    
    
    @State private var editingClassID: UUID? = nil
    @State private var editedClassName: String = ""
    
    // Для отображения Alert
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        HStack {
            Text(classData.name)
                .foregroundColor(selectedClass?.id == classData.id ? Color.red : Color.primary)
                .bold(selectedClass?.id == classData.id)
            
            Spacer()
            
            // Цветной прямоугольник
            Rectangle()
                .fill(classData.color.toColor())
                .frame(width: 30, height: 20)
                .cornerRadius(3)
                .onTapGesture {
                    editingClassID = classData.id
                    editedClassName = classData.name // Инициализируем редактируемое имя
                }
                .popover(isPresented: Binding<Bool>(
                    get: { editingClassID == classData.id },
                    set: { if !$0 { editingClassID = nil } }
                )) {
                    VStack {
                        ColorPicker("Выберите цвет", selection: Binding(
                            get: { classData.color.toColor() },
                            set: { newColor in
                                if let index = classList.firstIndex(where: { $0.id == classData.id }) {
                                    classList[index].color = ColorData.fromColor(newColor)
                                    saveClassListToFile()
                                    // Обновляем настройки проекта после изменения цвета
                                    saveProjectSettings()
                                }
                            }
                        ))
                        
                        // Поле для редактирования имени класса
                        TextField("Новое имя класса", text: $editedClassName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.top)
                            .onAppear {
                                if editingClassID == classData.id {
                                    editedClassName = classData.name
                                }
                            }
                        
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
                }
        }
        .contentShape(Rectangle()) // Делает всю строку tappable
        .onTapGesture {
            selectedClass = classData
        }
        .contextMenu {
            Button("Редактировать имя") {
                editingClassID = classData.id
                editedClassName = classData.name
            }
            Button("Удалить") {
                deleteClass()
            }
        }
        .padding(.vertical, 5)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Функции
    
    private func saveChanges() {
        let trimmedName = editedClassName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Проверка на пустое имя
        if trimmedName.isEmpty {
            alertMessage = "Имя класса не может быть пустым."
            showAlert = true
            return
        }
        
        // 2. Проверка на уникальность имени
        let nameExists = classList.contains { $0.name == trimmedName && $0.id != classData.id }
        if nameExists {
            alertMessage = "Имя класса уже существует."
            showAlert = true
            return
        }
        
        // 3. Поиск индекса класса для редактирования
        guard let index = classList.firstIndex(where: { $0.id == classData.id }) else {
            alertMessage = "Класс не найден."
            showAlert = true
            return
        }
        
        // 4. Обновление имени класса
        classList[index].name = trimmedName
        saveClassListToFile()
        editedClassName = ""
        editingClassID = nil
    }
    
    private func deleteClass() {
        if let index = classList.firstIndex(where: { $0.id == classData.id }) {
            classList.remove(at: index)
            saveClassListToFile()
        }
    }
}

struct ClassRowView_Previews: PreviewProvider {
    static var previews: some View {
        ClassRowView(
            classData: ClassData(name: "Example", color: ColorData(red: 1, green: 0, blue: 0)),
            selectedClass: .constant(nil),
            classList: .constant([]),
            saveClassListToFile: {},
            saveProjectSettings: {}
        )
    }
}
