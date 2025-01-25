//
//  LogViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 02.11.24.
//


import Foundation

class LogViewModel: ObservableObject {
    @Published var logs: [String] = []
    
    static let shared = LogViewModel()
    
    private init(){}
    
    func addLog(_ message: String) {
        DispatchQueue.main.async {
            self.logs.append(self.getCurrentTime() + ": " + message.localized)
        }
    }
    
    func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss" 
        return formatter.string(from: Date())
    }
}

func printLog(_ message: String, data: String = "") {
    

        let settings: Settings = Settings.shared
        guard let bundlePath = Bundle.main.path(forResource: settings.language.code, ofType: "lproj"),
              let languageBundle = Bundle(path: bundlePath) else {
            return
        }

     //   return NSLocalizedString(self, tableName: nil, bundle: languageBundle, value: "", comment: "")
    
  //  LogViewModel.shared.addLog(message)

    let result = String(format: NSLocalizedString(message, tableName: nil, bundle: languageBundle, value: "", comment: ""), data)
    LogViewModel.shared.addLog(result)
   // print(greeting) // "Hello, John!" (для английского)
    // "Привет, John!" (для русского)
}
