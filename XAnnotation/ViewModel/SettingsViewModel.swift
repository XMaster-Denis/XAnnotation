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
        var code: String {"\(self)"}
    }
    
    struct ExportProportions: Codable {
        var trainPercentage: Double = 70
        var testPercentage: Double = 15
        var validPercentage: Double = 15
    }
    
    @Published var exportProportions: ExportProportions = .init()
    
    @Published var language: Language = .en {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "SelectedLanguage")
            setAppLanguage(to: self.language.code)
        }
        
    }
    
    private var bundle: Bundle = .main
    
    func setAppLanguage(to languageCode: String) {
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    
    func setLanguage(_ languageCode: String) {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let languageBundle = Bundle(path: path) else {
            print("Error: Could not find language pack for \(languageCode)")
            return
        }

        bundle = languageBundle
      
        objectWillChange.send()
    }
    
    
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
                printLog("Error in UserDefaults: \(error.localizedDescription)")
            }
        }
        
        
    }
    

    
    func saveProportions() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(exportProportions) else { return }
        UserDefaults.standard.set(data, forKey: "ExportProportions")
    }
}

