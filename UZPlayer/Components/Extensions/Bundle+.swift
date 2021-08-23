//
//  Bundle++.swift
//  UZPlayerExample
//
//  Created by Nam Nguyen on 7/9/20.
//  Copyright © 2020 Nam Kennic. All rights reserved.
//

import Foundation
import UIKit

extension Bundle {
    
    func uzFontURL(forResource name: String?) -> URL? {
        if (self.bundleIdentifier?.hasPrefix("org.cocoapods"))! {
            return self.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts.bundle")
       } else {
           return self.url(forResource: name, withExtension: "ttf")
       }
    }
    
    func uzIconPath() -> String? {
        if (self.bundleIdentifier?.hasPrefix("org.cocoapods"))! {
             return self.path(forResource: "UZIcons", ofType: "bundle", inDirectory: "Icons.bundle")
         } else {
             return self.path(forResource: "UZIcons", ofType: "bundle")
         }
    }
    
    func getUZImage(named name: String) -> UIImage? {
        return UIImage(named: name, in: self, compatibleWith: nil)
    }
}
