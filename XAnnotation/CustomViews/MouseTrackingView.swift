//
//  MouseTrackingView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

struct MouseTrackingView: NSViewRepresentable {
    @Binding var cursorLocation: CGPoint
    var onMouseDown: ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint) -> Void)?
    var onMouseUp: (() -> Void)?

    func makeNSView(context: Context) -> MouseTrackingNSView {
        let view = MouseTrackingNSView()
        view.onMouseMoved = { location in
            DispatchQueue.main.async {
                self.cursorLocation = location
            }
        }
        view.onMouseDown = { location in
            DispatchQueue.main.async {
                self.onMouseDown?(location)
            }
        }
        view.onMouseDragged = { location in
            DispatchQueue.main.async {
                self.onMouseDragged?(location)
            }
        }
        view.onMouseUp = {
            DispatchQueue.main.async {
                self.onMouseUp?()
            }
        }
        return view
    }

    func updateNSView(_ nsView: MouseTrackingNSView, context: Context) {}
}
