//
//  UIViewController+TopPresented.swift
//  FireLock
//
//  Created by Nam Kennic on 5/9/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func topPresented() -> UIViewController? {
        
		if let window = UIApplication.shared.keyWindow,
            let viewController = window.rootViewController {
			var result: UIViewController? = viewController
			while result?.presentedViewController != nil {
				result = result?.presentedViewController
			}
			return result
		}
		
		return self
	}
	
	func topViewController() -> UIViewController? {
		var result: UIViewController? = self
		
		while let presentedViewController = result?.presentedViewController {
			result = presentedViewController
		}
		
		return result
	}
	
}
