//
//  ProjectSettings.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import SwiftUI

struct ProjectSettings: Codable {
    var foldersInProject: [String] = []
    var selectedFolder: String? = nil
    var allowImageRotation: Bool = false
    var selectedImageURL: String?
}
