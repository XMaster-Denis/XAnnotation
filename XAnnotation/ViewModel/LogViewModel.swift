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
            self.logs.append(self.getCurrentTime() + ": " + message)
        }
    }
    
    func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss" 
        return formatter.string(from: Date())
    }
}

func printLog(_ message: String) {
    LogViewModel.shared.addLog(message)
}
