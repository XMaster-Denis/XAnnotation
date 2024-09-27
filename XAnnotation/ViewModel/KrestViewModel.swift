//
//  KrestViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 27.09.24.
//

import Foundation

class KrestViewModel: ObservableObject {
    @Published var hoverLocation: CGPoint = .zero
    @Published var isHovering = false
}
