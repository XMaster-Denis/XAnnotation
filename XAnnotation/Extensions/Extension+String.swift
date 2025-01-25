//
//  Extension+String.swift
//  XAnnotation
//
//  Created by XMaster on 02.11.24.
//
import SwiftUI

extension String {
    var localized: String {
        let settings: Settings = Settings.shared
        guard let bundlePath = Bundle.main.path(forResource: settings.language.code, ofType: "lproj"),
              let languageBundle = Bundle(path: bundlePath) else {
            return self
        }

        return NSLocalizedString(self, tableName: nil, bundle: languageBundle, value: "", comment: "")
    }
}

