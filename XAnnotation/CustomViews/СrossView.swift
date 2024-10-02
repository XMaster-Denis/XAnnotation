//
//  KrestView.swift
//  XAnnotation
//
//  Created by XMaster on 27.09.24.
//

import SwiftUI


struct СrossView: View {
    
    @EnvironmentObject var krestData: СrossViewModel
    var imageOrigin: CGPoint
    var imageSize: CGSize
    
    var body: some View {
        ZStack {
            if krestData.isHovering{
                let top: CGPoint = .init(x: krestData.hoverLocation.x, y: imageOrigin.y)
                let bottom: CGPoint = .init(x: krestData.hoverLocation.x, y: imageSize.height + imageOrigin.y)
                let left: CGPoint = .init(x: imageOrigin.x, y: krestData.hoverLocation.y)
                let right: CGPoint = .init(x: imageSize.width + imageOrigin.x, y: krestData.hoverLocation.y)
                
                Path {p in
                    p.addLines([top,bottom])
                }
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 8]))
                .foregroundStyle(.blue)
                
                Path {p in
                    p.addLines([left,right])
                }
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 8]))
                .foregroundStyle(.blue)
                
            }
        }

    }
}

