//
//  UIDeviceExtension.swift
//  BFKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 - 2017 Fabrizio Brancati. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import UIKit

// MARK: - UIDevice extension

/// This extesion adds some useful functions to UIDevice
extension UIDevice {
	
	func hardwareModel() -> String {
		var size = 0
		sysctlbyname("hw.machine", nil, &size, nil, 0)
		var machine = [CChar](repeating: 0, count: Int(size))
		sysctlbyname("hw.machine", &machine, &size, nil, 0)
		return String(cString: machine)
	}
	
	func hardwareName() -> String {
		let model = self.hardwareModel()
		
		switch model {
		// iPhone 2G
		case "iPhone1,1":       return "iPhone 2G"
		// iPhone 3G
		case "iPhone1,2":       return "iPhone 3G"
		// iPhone 3GS
		case "iPhone2,1":       return "iPhone 3GS"
		// iPhone 4
		case "iPhone3,1":       return "iPhone 4"
		case "iPhone3,2":       return "iPhone 4"
		case "iPhone3,3":       return "iPhone 4"
		// iPhone 4S
		case "iPhone4,1":       return "iPhone 4S"
		// iPhone 5
		case "iPhone5,1":       return "iPhone 5"
		case "iPhone5,2":       return "iPhone 5"
		// iPhone 5c
		case "iPhone5,3":       return "iPhone 5c"
		case "iPhone5,4":       return "iPhone 5c"
		// iPhone 5s
		case "iPhone6,1":       return "iPhone 5s"
		case "iPhone6,2":       return "iPhone 5s"
		// iPhone 6 / 6 Plus
		case "iPhone7,1":       return "iPhone 6 Plus"
		case "iPhone7,2":       return "iPhone 6"
		// iPhone 6s / 6s Plus
		case "iPhone8,1":       return "iPhone 6s"
		case "iPhone8,2":       return "iPhone 6s Plus"
		// iPhone SE
		case "iPhone8,4":       return "iPhone SE"
		// iPhone 7 / 7 Plus
		case "iPhone9,1":       return "iPhone 7"
		case "iPhone9,2":       return "iPhone 7 Plus"
		case "iPhone9,3":       return "iPhone 7"
		case "iPhone9,4":       return "iPhone 7 Plus"
		// iPhone 8 / 8 Plus
		case "iPhone10,1":      return "iPhone 8"
		case "iPhone10,2":      return "iPhone 8 Plus"
		case "iPhone10,4":      return "iPhone 8"
		case "iPhone10,5":      return "iPhone 8 Plus"
		// iPhone X
		case "iPhone10,3":      return "iPhone X"
		case "iPhone10,6":      return "iPhone X"
		// iPhone XS / iPhone XS Max
		case "iPhone11,2":      return "iPhone XS"
		case "iPhone11,4":      return "iPhone XS Max"
		case "iPhone11,6":      return "iPhone XS Max"
		// iPhone XR
		case "iPhone11,8":      return "iPhone XR"
		// iPod touch
		case "iPod1,1":         return "iPod touch (1st generation)"
		case "iPod2,1":         return "iPod touch (2nd generation)"
		case "iPod3,1":         return "iPod touch (3rd generation)"
		case "iPod4,1":         return "iPod touch (4th generation)"
		case "iPod5,1":         return "iPod touch (5th generation)"
		case "iPod7,1":         return "iPod touch (6th generation)"
		// iPad / iPad Air
		case "iPad1,1":         return "iPad"
		case "iPad2,1":         return "iPad 2"
		case "iPad2,2":         return "iPad 2"
		case "iPad2,3":         return "iPad 2"
		case "iPad2,4":         return "iPad 2"
		case "iPad3,1":         return "iPad 3"
		case "iPad3,2":         return "iPad 3"
		case "iPad3,3":         return "iPad 3"
		case "iPad3,4":         return "iPad 4"
		case "iPad3,5":         return "iPad 4"
		case "iPad3,6":         return "iPad 4"
		case "iPad4,1":         return "iPad Air"
		case "iPad4,2":         return "iPad Air"
		case "iPad4,3":         return "iPad Air"
		case "iPad5,3":         return "iPad Air 2"
		case "iPad5,4":         return "iPad Air 2"
		case "iPad6,11":         return "iPad Air 2"
		case "iPad6,12":         return "iPad Air 2"
		// iPad mini
		case "iPad2,5":         return "iPad mini"
		case "iPad2,6":         return "iPad mini"
		case "iPad2,7":         return "iPad mini"
		case "iPad4,4":         return "iPad mini 2"
		case "iPad4,5":         return "iPad mini 2"
		case "iPad4,6":         return "iPad mini 2"
		case "iPad4,7":         return "iPad mini 3"
		case "iPad4,8":         return "iPad mini 3"
		case "iPad4,9":         return "iPad mini 3"
		// iPad Pro 9.7
		case "iPad6,3":         return "iPad Pro (9.7-inch)"
		case "iPad6,4":         return "iPad Pro (9.7-inch)"
		// iPad Pro 10.5
		case "iPad7,3":         return "iPad Pro (10.5-inch)"
		case "iPad7,4":         return "iPad Pro (10.5-inch)"
		// iPad Pro 11
		case "iPad8,1":         return "iPad Pro (11-inch)"
		case "iPad8,2":         return "iPad Pro (11-inch)"
		case "iPad8,3":         return "iPad Pro (11-inch)"
		case "iPad8,4":         return "iPad Pro (11-inch)"
		// iPad Pro 12.9
		case "iPad6,7":         return "iPad Pro (12.9-inch)"
		case "iPad6,8":         return "iPad Pro (12.9-inch)"
		case "iPad7,1":         return "iPad Pro (12.9-inch, 2nd generation)"
		case "iPad7,2":         return "iPad Pro (12.9-inch, 2nd generation)"
		case "iPad8,5":         return "iPad Pro (12.9-inch, 3rd generation)"
		case "iPad8,6":         return "iPad Pro (12.9-inch, 3rd generation)"
		case "iPad8,7":         return "iPad Pro (12.9-inch, 3rd generation)"
		case "iPad8,8":         return "iPad Pro (12.9-inch, 3rd generation)"
		// Apple TV
		case "AppleTV2,1":      return "Apple TV (2nd generation)"
		case "AppleTV3,1":      return "Apple TV (3rd generation)"
		case "AppleTV3,2":      return "Apple TV (3rd generation)"
		case "AppleTV5,3":      return "Apple TV (4th generation)"
		case "AppleTV6,2":      return "Apple TV 4K"
		// Simulator
		case "i386", "x86_64":  return "Simulator"
		default:
			return model
		}
	}
	
	public static func isPhone() -> Bool {
		return current.userInterfaceIdiom == .phone
	}
	
	public static func isPad() -> Bool {
		return current.userInterfaceIdiom == .pad
	}
	
	public static func isTV() -> Bool {
		if #available(iOS 9.0, *) {
			return current.userInterfaceIdiom == .tv
		} else {
			return false
		}
	}
	
	public static func isSimulator() -> Bool {
		return self.current.hardwareName() == "Simulator"
	}
	
	#if os(iOS)
	public static func isPortrait() -> Bool {
		return UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.portrait ||
            UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.portraitUpsideDown
	}
	
	public static func isLandscape() -> Bool {
		return UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeLeft ||
            UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeRight
	}
	
	public static func isCarPlay() -> Bool {
		if #available(iOS 9.0, *) {
			return current.userInterfaceIdiom == .carPlay
		} else {
			return false
		}
	}
	#endif
	
//	public static func isJailbroken() -> Bool {
//		return UIApplication.shared.canOpenURL(URL(string: "cydia://")!) || FileManager.default.fileExists(atPath: "/bin/bash")
//	}
	
}
