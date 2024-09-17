//
//  MouseTrackingNSView.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import Foundation

import AppKit

class MouseTrackingNSView: NSView {
    var onMouseMoved: ((CGPoint) -> Void)?
    var onMouseDown: ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint) -> Void)?
    var onMouseUp: (() -> Void)?

    private var lastMouseMoveTime: TimeInterval = 0

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        self.trackingAreas.forEach { self.removeTrackingArea($0) }
        let options: NSTrackingArea.Options = [.mouseMoved, .activeInKeyWindow, .inVisibleRect]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseMoved(with event: NSEvent) {
        let currentTime = Date().timeIntervalSinceReferenceDate
        // Ограничиваем частоту обновлений до 60 раз в секунду
        if currentTime - lastMouseMoveTime > (1.0 / 60.0) {
            lastMouseMoveTime = currentTime
            let locationInView = self.convert(event.locationInWindow, from: nil)
            let flippedLocation = CGPoint(x: locationInView.x, y: self.bounds.height - locationInView.y)
            onMouseMoved?(flippedLocation)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)
        let flippedLocation = CGPoint(x: locationInView.x, y: self.bounds.height - locationInView.y)
        onMouseDown?(flippedLocation)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)
        let flippedLocation = CGPoint(x: locationInView.x, y: self.bounds.height - locationInView.y)
        onMouseDragged?(flippedLocation)
    }
    
    override func mouseUp(with event: NSEvent) {
        onMouseUp?()
    }
}
