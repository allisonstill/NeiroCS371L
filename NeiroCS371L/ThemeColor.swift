//
//  ThemeColor.swift
//  NeiroCS371L
//
//  Created by Allison Still on 10/18/25.
//

import Foundation
import UIKit

enum ThemeColor {
    enum Color {
        static let backgroundColor = UIColor(named: "PrimaryBackground")!
        static let titleColor = UIColor(named: "TitleColor")!
        static let textColor = UIColor(named: "TextColor")!
        static let titleOutline = UIColor(named: "TitleOutline")!
    }
    
    enum Font {
        static func titleFont() -> UIFont {
            return UIFont(name: "STIX Two Math", size: 64.0)!
        }
        
        static func bodyAuthFont() -> UIFont {
            return UIFont(name: "Helvetica Neue", size: 19.0)!
        }
    }
}
