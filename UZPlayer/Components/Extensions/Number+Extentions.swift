//
//  Number+Extentions.swift
//  Yup
//
//  Created by Nam Kennic on 8/29/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import Foundation

extension Int {
	
	/**
	Value : 598 -> 598
	Value : -999 -> -999
	Value : 1000 -> 1K
	Value : -1284 -> -1.3K
	Value : 9940 -> 9.9K
	Value : 9980 -> 10K
	Value : 39900 -> 39.9K
	Value : 99880 -> 99.9K
	Value : 399880 -> 0.4M
	Value : 999898 -> 1M
	Value : 999999 -> 1M
	Value : 1456384 -> 1.5M
	Value : 12383474 -> 12.4M
	*/
	var abbreviated: String {
		let abbrev = "KMBTPE"
		return abbrev.enumerated().reversed().reduce(nil as String?) { accum, tuple in
			let factor = Double(self) / pow(10, Double(tuple.0 + 1) * 3)
			let format = (factor.truncatingRemainder(dividingBy: 1)  == 0 ? "%.0f%@" : "%.1f%@")
			return accum ?? (factor > 1 ? String(format: format, factor, String(tuple.1)) : nil)
			} ?? String(self)
	}
	
	/**
	31908551587 -> 31,908,551,587
	*/
	func withCommas() -> String {
		let numberFormatter = NumberFormatter()
		numberFormatter.numberStyle = NumberFormatter.Style.decimal
		return numberFormatter.string(from: NSNumber(value: self))!
	}
	
	/**
	limit = 10000 -> 9999, 10K
	*/
	func abbreviatedFromLimit(limit: Int) -> String {
		if self >= limit {
			return self.abbreviated
		} else {
			return self.withCommas()
		}
	}
	
}
