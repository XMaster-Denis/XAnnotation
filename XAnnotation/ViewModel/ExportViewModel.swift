//
//  ExportViewModel.swift
//  XAnnotation
//
//  Created by XMaster on 08.10.24.
//
import SwiftUI

class ExportViewModel: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
}
