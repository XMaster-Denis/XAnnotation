//
//  KrestViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 27.09.24.
//

import Foundation

class СrossViewModel: ObservableObject {
    @Published var hoverLocation: CGPoint = .zero
    @Published var isHovering = false
    
    func updateCrossData(_ newValue: CGPoint) {
        hoverLocation = newValue
        // Дополнительная логика сохранения или обновления
    }
    
    func updateCrossStatus(_ newValue: Bool) {
        isHovering = newValue
        // Дополнительная логика сохранения или обновления
    }
}

