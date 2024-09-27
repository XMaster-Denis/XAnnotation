//
//  ClassDataViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 27.09.24.
//
import Foundation

class ClassDataViewModel: ObservableObject {
    @Published var classList: [ClassData] = []
    @Published var selectedClass: ClassData?
    
    var projectData: ProjectDataViewModel
    
    init(projectData: ProjectDataViewModel) {
        self.projectData = projectData
    }
    
    func loadClassListFromFile() {
        do {
            if let projectURL = projectData.projectURL {
                let classesFileURL = projectURL.appendingPathComponent("classes.json")
                let jsonData = try Data(contentsOf: classesFileURL)
                let decoder = JSONDecoder()
                classList = try decoder.decode([ClassData].self, from: jsonData)
                print("Список классов загружен из файла.")
                
                // Устанавливаем выбранный класс, если он не установлен
                if selectedClass == nil, let firstClass = classList.first {
                    selectedClass = firstClass
                }
            }
        } catch {
            print("Ошибка при загрузке списка классов: \(error.localizedDescription)")
        }
    }
}
