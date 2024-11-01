//
//  SettingsViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 24.10.24.
//

import SwiftUI

class Settings: ObservableObject {
    
    static let shared = Settings()
    
    enum Language: String, CaseIterable, Identifiable {
        case en = "English"
        case de = "Deutsch"
        case ru = "Русский"

        var id: String { self.rawValue }
    }
    
    @Published var language: Language = .en {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "SelectedLanguage")
        }
    }
    
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "SelectedLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.language = language
        } else {
            self.language = .en
        }
    }
}

