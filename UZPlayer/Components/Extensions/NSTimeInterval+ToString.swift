//
//  NSTimeInterval+ToString.swift
//  Uiza
//
//  Created by Nam Kennic on 10/12/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import Foundation

extension TimeInterval {
	
	var toString: String {
		if self.isNaN {
			return "--:--"
		}
		
		let interval = Int(self)
		let seconds = interval % 60
		let minutes = (interval / 60) % 60
		let hours	= (interval / 3600)
		
		return hours>0 ? String(format: "%02d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
	}
	
    var toLiveString: String {
        if self.isNaN {
            return "--:--"
        }
        
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours    = (interval / 3600)
        
        return hours>0 ? String(format: "-%02d:%02d:%02d", hours, minutes, seconds) : String(format: "-%02d:%02d", minutes, seconds)
    }
}
