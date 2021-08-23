//
//  UZSubtitles.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 11/7/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import Foundation

public class UZSubtitles {
	public var groups: [UZSubtitleGroup] = []
	
	public struct UZSubtitleGroup: CustomStringConvertible {
		var index: Int
		var start: TimeInterval
		var end: TimeInterval
		var text: String
		
		init(_ index: Int, _ start: NSString, _ end: NSString, _ text: NSString) {
			self.index = index
			self.start = UZSubtitleGroup.parseDuration(start as String)
			self.end   = UZSubtitleGroup.parseDuration(end as String)
			self.text  = text as String
		}
		
		static func parseDuration(_ fromStr: String) -> TimeInterval {
			var h: TimeInterval = 0.0, m: TimeInterval = 0.0, s: TimeInterval = 0.0, c: TimeInterval = 0.0
			let scanner = Scanner(string: fromStr)
			scanner.scanDouble(&h)
			scanner.scanString(":", into: nil)
			scanner.scanDouble(&m)
			scanner.scanString(":", into: nil)
			let isHasSeconds = scanner.scanDouble(&s)
            if !isHasSeconds {
                s = m
                m = h
            }
			scanner.scanString(",", into: nil)
			scanner.scanDouble(&c)
			return (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
		}
		
		public var description: String {
			return "Subtile UZSubtitleGroup ==========\nindex : \(index),\nstart : \(start)\nend   :\(end)\ntext  :\(text)"
		}
	}
	
	public init(url: URL, encoding: String.Encoding? = nil) {
		DispatchQueue.global(qos: .background).async {
			do {
				let string: String
				if let encoding = encoding {
					string = try String(contentsOf: url, encoding: encoding)
				} else {
					string = try String(contentsOf: url)
				}
            
				self.groups = UZSubtitles.parseSubRip(string) ?? []
			} catch {
                UZSentry.sendError(error: error)
				DLog("[UZPlayer] [Error] failed to load \(url.absoluteString) \(error.localizedDescription)")
			}
		}
	}
	
	/**
	Search for target group for time
	- parameter time: target time
	- returns: result group or nil
	*/
	public func search(for time: TimeInterval) -> UZSubtitleGroup? {
		let result = groups.first(where: { group -> Bool in
			if group.start <= time && group.end >= time {
				return true
			}
			return false
		})
		
		return result
	}
	
	/**
	Parse str string into UZSubtitleGroup Array
	- parameter payload: target string
	- returns: result group
	*/
	fileprivate static func parseSubRip(_ payload: String) -> [UZSubtitleGroup]? {
		var groups: [UZSubtitleGroup] = []
		let scanner = Scanner(string: payload)
		while !scanner.isAtEnd {
			var indexString: NSString?
			scanner.scanUpToCharacters(from: .newlines, into: &indexString)
            if Int(indexString as String? ?? "") == nil {
                scanner.scanUpToCharacters(from: .newlines, into: &indexString)
            }
			
			var startString: NSString?
			scanner.scanUpTo(" --> ", into: &startString)
			scanner.scanString("-->", into: nil)
			
			var endString: NSString?
			scanner.scanUpToCharacters(from: .newlines, into: &endString)
			
			var textString: NSString?
			scanner.scanUpTo("\r\n\r\n", into: &textString)
			
			if let text = textString {
				textString = text.trimmingCharacters(in: .whitespaces) as NSString
				textString = text.replacingOccurrences(of: "\r", with: "") as NSString
			}
			
			if let indexString = indexString,
				let index = Int(indexString as String),
				let start = startString,
				let end   = endString,
				let text  = textString {
				let group = UZSubtitleGroup(index, start, end, text)
				groups.append(group)
			}
		}
		return groups
	}
    
}
