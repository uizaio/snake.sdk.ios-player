//
//  UZAirPlayButton.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import MediaPlayer

open class UZAirPlayButton: MPVolumeView {
	
	open var isEnabled: Bool = true {
		didSet {
			self.isUserInteractionEnabled = isEnabled
			self.alpha = isEnabled ? 1.0 : 0.6
		}
	}
	
	convenience init(iconSize: CGSize = CGSize(width: 24, height: 24)) {
		self.init()
		setupDefaultIcon(iconSize: iconSize)
	}

	init() {
		super.init(frame: .zero)
		
		self.showsRouteButton = true
		self.showsVolumeSlider = false
		self.backgroundColor = .clear
		self.isHidden = !self.areWirelessRoutesAvailable
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open func setupDefaultIcon(iconSize: CGSize, offColor: UIColor = .white, onColor: UIColor = UIColor(red: 0.21, green: 0.49, blue: 0.96, alpha: 1.00)) {
		let airplayOffIcon = UIImage(icon: .googleMaterialDesign(.airplay), size: iconSize, textColor: offColor, backgroundColor: .clear)
		let airplayOnIcon = UIImage(icon: .googleMaterialDesign(.airplay), size: iconSize, textColor: onColor, backgroundColor: .clear)
		
		self.setImage(image: airplayOffIcon, for: .normal)
		self.setImage(image: airplayOnIcon, for: .selected)
	}
	
	open func setImage(image: UIImage?, for state: UIControl.State) {
		self.setRouteButtonImage(image, for: state)
	}
	
	override open func sizeThatFits(_ size: CGSize) -> CGSize {
		if let image = self.routeButtonImage(for: .normal) {
			return image.size
		}
		
		return CGSize(width: 24, height: 24)
	}

}
