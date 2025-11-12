//
//  ThemeManager.swift
//  NeiroCS371L
//
//  Created by Ethan Yu on 11/11/25.
//

import Foundation
import UIKit


enum AppAppearance: String {
    case system, light, dark
}

enum ThemeManager {
    private static let key = "appAppearance"

    static var current: AppAppearance {
        if let raw = UserDefaults.standard.string(forKey: key),
           let v = AppAppearance(rawValue: raw) { return v }
        return .system
    }

    static func set(_ appearance: AppAppearance) {
        UserDefaults.standard.set(appearance.rawValue, forKey: key)
        applyToAllWindows(appearance)
    }

    static func applyToAllWindows(_ appearance: AppAppearance = current) {
        let style: UIUserInterfaceStyle = {
            switch appearance {
            case .system: return .unspecified
            case .light:  return .light
            case .dark:   return .dark
            }
        }()

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}

