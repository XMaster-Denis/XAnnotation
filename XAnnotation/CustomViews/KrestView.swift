//
//  KrestView.swift
//  XAnnotation
//
//  Created by XMaster on 27.09.24.
//

import SwiftUI


struct KrestView: View {
    
    @EnvironmentObject var krestData: KrestViewModel
    
    
    var body: some View {
        if krestData.isHovering{
        let top: CGPoint = .init(x: krestData.hoverLocation.x, y: 0)
        let bottom: CGPoint = .init(x: krestData.hoverLocation.x, y: 5000)
        let left: CGPoint = .init(x: 0, y: krestData.hoverLocation.y)
        let right: CGPoint = .init(x: 5000, y: krestData.hoverLocation.y)
        
            Path {p in
                p.addLines([top,bottom])
            }
            .strokedPath(StrokeStyle(lineWidth: 3, lineCap: .round))
            .foregroundStyle(.blue)
              
            Path {p in
                p.addLines([left,right])
            }
            .strokedPath(StrokeStyle(lineWidth: 3, lineCap: .round))
            .foregroundStyle(.blue)
      
        }
    }
}

