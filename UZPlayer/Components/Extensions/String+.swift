//
//  String+.swift
//  UZPlayerExample
//
//  Created by Nam Nguyen on 7/17/20.
//  Copyright © 2020 namndev. All rights reserved.
//

import Foundation

// Extend the String object with helpers
extension String {

    // String.replace(); similar to JavaScript's String.replace() and Ruby's String.gsub()
    public func replace(_ pattern: String, replacement: String) throws -> String {

        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        return regex.stringByReplacingMatches(
            in: self,
            options: [.withTransparentBounds],
            range: NSRange(location: 0, length: self.count),
            withTemplate: replacement
        )
    }
    
    public func capitalizingFirstLetter() -> String {
           return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
