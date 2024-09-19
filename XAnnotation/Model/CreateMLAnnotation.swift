//
//  CreateMLAnnotation.swift
//  XAnnotation
//
//  Created by XMaster on 19.09.24.
//
import SwiftUI

struct CreateMLAnnotation: Codable {
    let image: String
    let annotations: [CreateMLRegion]
}

struct CreateMLRegion: Codable {
    let label: String
    let coordinates: CreateMLCoordinates
}

struct CreateMLCoordinates: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}
