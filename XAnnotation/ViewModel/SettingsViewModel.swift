//
//  SettingsViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 24.10.24.
//

import SwiftUI

class Settings: ObservableObject {
    
    static let shared = Settings()
    
    @Published var showExportSettingsView: Bool = false
    
    enum Language: String, CaseIterable, Identifiable {
        case en = "English"
        case de = "Deutsch"
        case ru = "Русский"
        
        var id: String { self.rawValue }
    }
    
    struct ExportProportions: Codable {
        var trainPercentage: Double = 70
        var testPercentage: Double = 15
        var validPercentage: Double = 15
    }
    
    @Published var exportProportions: ExportProportions = .init() {
        didSet{
//            let encoder = JSONEncoder()
//            guard let data = try? encoder.encode(exportProportions) else { return }
//            UserDefaults.standard.set(data, forKey: "ExportProportions")
            
            
//            var path: [AnyObject] = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true) as [AnyObject]
//                let folder: String = path[0] as! String
//                NSLog("Your NSUserDefaults are stored in this folder: %@/Preferences", folder)
//            UserDefaults.standard.set(exportProportions.trainPercentage, forKey: "TrainPercentage")
//            UserDefaults.standard.set(exportProportions.testPercentage, forKey: "TestPercentage")
//            UserDefaults.standard.set(exportProportions.validPercentage, forKey: "ValidPercentage")
        }
    }
    
    @Published var language: Language = .en {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "SelectedLanguage") }
    }
    //
    //    @Published var trainPercentage: Double = 70 {
    //        didSet { UserDefaults.standard.set(trainPercentage, forKey: "TrainPercentage") }
    //    }
    //
    //    @Published var testPercentage: Double = 15 {
    //        didSet { UserDefaults.standard.set(testPercentage, forKey: "TestPercentage") }
    //    }
    //
    //    @Published var validPercentage: Double = 15 {
    //        didSet { UserDefaults.standard.set(validPercentage, forKey: "ValidPercentage") }
    //    }
    //    do {
    //        let encoder = JSONEncoder()
    //        encoder.outputFormatting = .prettyPrinted
    //        let data = try encoder.encode(annotations)
    //        try data.write(to: annotationsURL)
    //        print("Аннотации успешно сохранены по адресу: \(annotationsURL.path)")
    //    } catch {
    //        print("Ошибка при сохранении аннотаций: \(error.localizedDescription)")
    //    }
    
    
    private init() {
        
        if let savedLanguage = UserDefaults.standard.string(forKey: "SelectedLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.language = language
        } else {
            self.language = .en
        }
        
        let decoder = JSONDecoder()
        if let savedProportions = UserDefaults.standard.data(forKey: "ExportProportions")
        {
            do {
                exportProportions = try decoder.decode(ExportProportions.self, from: savedProportions)
            } catch {
                print("Error in UserDefaults: \(error.localizedDescription)")
            }
        }
        
        
    }
    
    func saveProportions() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(exportProportions) else { return }
        UserDefaults.standard.set(data, forKey: "ExportProportions")
    }
}

