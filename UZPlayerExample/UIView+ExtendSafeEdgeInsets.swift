//
//  UIView+ExtendSafeEdgeInsets.swift
//  UIView
//
//  Created by Nam Kennic on 1/3/19.
//  Copyright © 2019 Nam Kennic. All rights reserved.
//

import UIKit

fileprivate var extendSafeAreaInsets: UIEdgeInsets = .zero

extension UIView {
	
	var extendSafeEdgeInsets: UIEdgeInsets {
		let hasNotch = UIDevice.current.isIPhoneXType()
		if extendSafeAreaInsets == .zero || (hasNotch && extendSafeAreaInsets.top == 0) {
			if #available(iOS 11.0, *) {
				var safeAreaInsets: UIEdgeInsets? = .zero
				if #available(iOS 13.0, *) {
					safeAreaInsets = UIApplication.shared.windows.first(where: {$0.isKeyWindow})?.safeAreaInsets
				}
				else {
					safeAreaInsets = UIApplication.shared.keyWindow?.safeAreaInsets
				}
				if safeAreaInsets == nil { safeAreaInsets = UIWindow().safeAreaInsets }
				
				if extendSafeAreaInsets.top < 24 && hasNotch {
                    extendSafeAreaInsets = .zero
                    return UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
				}
			}
		}
		return extendSafeAreaInsets
	}
	
}

extension UIDevice {
	
	func isIPhoneXType() -> Bool {
		var iphoneXs: [CGFloat] = [2688, 2436, 1792]
		iphoneXs.append(2340) // iphone 12 mini
		iphoneXs.append(2532) // iphone 12 pro
		iphoneXs.append(2778) // iphone 12 pro max
		return userInterfaceIdiom == .phone && iphoneXs.contains(UIScreen.main.nativeBounds.height)
	}
	
}
