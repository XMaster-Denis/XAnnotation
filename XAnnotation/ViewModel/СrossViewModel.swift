//
//  KrestViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 27.09.24.
//

import Foundation

class СrossViewModel: ObservableObject {
    static let shared = СrossViewModel()
    
    @Published var hoverLocation: CGPoint = .zero
    @Published var isHovering = false
    
    func updateCrossData(_ newValue: CGPoint) {
        hoverLocation = newValue
    }
    
    func updateCrossStatus(_ newValue: Bool) {
        isHovering = newValue
    }
}

