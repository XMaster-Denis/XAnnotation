//
//  ProjectSettings.swift
//  XAnnotation
//
//  Created by XMaster on 17.09.24.
//

import Foundation

struct ProjectSettings: Codable {
    var foldersInProject: [String]
    var selectedFolder: String?
}
